function render(
    i::Union{AOIntegrator, SimpleIntegrator, SimpleVolPathIntegratorv4, VolPathIntegratorv3}, 
    scene::Scene, 
    ::Dict{String, Any},
    ::Tuple{Int64,Int64}  
)
    sample_bounds = get_sample_bounds(i.camera.core.core.film)
    sample_extent = diagonal(sample_bounds)
    tile_size = 16
    width, height = Int64.(floor.((sample_extent .+ tile_size) ./ tile_size))
    total_tiles = width * height - 1
    print("Rendering " * num2str(total_tiles + 1) * " tiles\n")

    prog = Progress(total_tiles)
    update!(prog,0)
    jj = Threads.Atomic{Int}(0)
    l = Threads.SpinLock()

    print("Utilizing $(Threads.nthreads()) threads\n")
    Threads.@threads for k in 0:total_tiles
        # this is a bullshit ass hack
        for wtf in 1:length(scene.b.primitives)
            if !(scene.b.primitives[wtf].mi.inside isa Nothing)
                if scene.b.primitives[wtf].mi.inside isa NanoVDBMedium
                    NanoVDB.init(scene.b.primitives[wtf].mi.inside.nanovdb_grid)
                end
            end
            if !(scene.b.primitives[wtf].mi.outside isa Nothing)
                if scene.b.primitives[wtf].mi.outside isa NanoVDBMedium
                    NanoVDB.init(scene.b.primitives[wtf].mi.outside.nanovdb_grid)
                end
            end
        end
        
        x, y = k % width, k ÷ width
        tile = Pnt2(x, y)
        seed = Int64(tile.y * width + tile.x)
        sampler = clone(i.sampler, seed)

        tb_min = sample_bounds.pMin .+ tile .* tile_size
        tb_max = min.(tb_min .+ (tile_size - 1), sample_bounds.pMax)
        tile_bounds = Bounds2i(tb_min, tb_max)
        film_tile = FilmTile(i.camera.core.core.film, tile_bounds)
        for pixel in tile_bounds # adding iterator method is cool
            @info "WORKING ON PIXEL $pixel"
            for sample_index in 1:sampler.samples_per_pixel
                start_pixel_sample!(sampler, pixel, sample_index-1)

                camera_sample = get_camera_sample!(sampler, pixel)
                @info "camera_sample: $camera_sample"
                ray, w = generate_ray_differential(i.camera, camera_sample)
                scale_differentials!(ray, 1.0 / sqrt(sampler.samples_per_pixel))
                L = spectrum_from_float(0.0)

                if w > 0
                    L = li(i, ray, scene, 0, sampler)
                end

                if any(isnan.(L))
                    L = spectrum_from_float(0.0)
                end

                add_sample!(film_tile, camera_sample.film, L, 1.0)
            end
        end
        merge_film_tile!(i.camera.core.core.film , film_tile)
        # print("$(k)\n")
        Threads.atomic_add!(jj,1)
        Threads.lock(l)
        update!(prog, jj[])
        Threads.unlock(l)
    end
    @time got_film = i.camera.core.core.film
    img = save(got_film)
    return img
end

function uniform_sample_one_light(
    isect::SurfaceInteraction, 
    scene::Scene, 
    sampler::AbstractSampler, 
    light_distribution::Distribution1D,
    handle_media::Bool=false, 
)::Spectrum
    # chose a single light to sample
    light_num, light_pdf, _ = sample_discrete(light_distribution, get_1D!(sampler))
    light = scene.lights[light_num]

    u_light = get_2D!(sampler)
    u_scattering = get_2D!(sampler)
    return estimate_direct(isect, u_scattering, light, u_light, scene, sampler, handle_media, false) / light_pdf
end

function estimate_direct(
    isect::SurfaceInteraction, 
    u_scattering::Pnt2, 
    light::Light, 
    u_light::Pnt2, 
    scene::Scene, 
    sampler::AbstractSampler, 
    handle_media::Bool=false, 
    specular::Bool=false
)::Spectrum
    bsdf_flags = specular ? BSDF_ALL : (BSDF_ALL & ~BSDF_SPECULAR)
    Ld = spectrum_from_float(0.0)
    
    # sample light source with multiple importance sampling
    Li, wi, light_pdf, vis, _, _  = sample_li(light, isect.core, u_light)
    if light_pdf > 0
        # compute BSDF or phase functions value for light sample
        # TODO: not checking for phase function, assuming is surface interaction
        f = isect.bsdf(isect.core.wo, wi, bsdf_flags) * abs(dot(wi, isect.shading.n))
        scattering_pdf = 0.0

        # IF NOT BLACK
        # compute effect of visibility for light source sample
        if handle_media
            @assert false
        else
            if !unoccluded(vis, scene.b)
                Li = spectrum_from_float(0.0)
            end
        end

        # add light's contribution to reflected radiance
        # IF NOT BLACK
        if is_delta_light(light)
            Ld += f * Li / light_pdf
        else
            weight = power_heuristic(1.0, light_pdf, 1.0, scattering_pdf)
            Ld += f * Li * weight / light_pdf
        end
    end

    # sampling BSDF with multiple importance sampling
    if !is_delta_light(light)
        # ASSUMING THIS IS A SURFACE INTERACTION 
        # sample scattered direction for surface interaction
        wi, f, scattering_pdf, sampled_type = sample_f(isect.bsdf, isect.core.wo, u_scattering, bsdf_flags)
        f *= abs(dot(wi, isect.shading.n))
        sampled_specular = sampled_type & BSDF_SPECULAR == sampled_type
    end

    # ASSUMING IS NOT BLACK
    if scattering_pdf > 0 
        # account for light contributions along sampled direction wi
        weight = 1.0
        if !sampled_specular
            light_pdf = pdf_li(light, isect, wi)
            (light_pdf == 0) && return Ld
            weight = power_heuristic(1.0, scattering_pdf, 1.0, light_pdf)
        end

        # find intersection and compute transmittance
        ray = spawn_ray(isect.core, wi)
        Tr = spectrum_from_float(1.0, 1.0, 1.0)
        # assuming no media to handle
        found_surface_interaction, t, light_isect = intersect!(scene.b, ray)

        # add light contribution from material sampling
        Li = spectrum_from_float(0.0)
        if found_surface_interaction
            if !(light_isect.primitive.area_light isa Nothing)
                Li = le(light_isect, -wi)
            end
        else
            Li = le(light, ray)
        end
        # IF NOT BLACK
        Ld += f * Li * Tr * weight / scattering_pdf
    end
    return Ld
end
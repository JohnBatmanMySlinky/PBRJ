function render(
    i::Union{AOIntegrator, SimpleIntegrator, SimpleVolPathIntegratorv4, VolPathIntegratorv3}, 
    scene::Scene, 
    ::Dict{String, Any},
    ::Tuple{Int64,Int64}  
)
    sample_bounds = get_sample_bounds(i.camera.core.core.film)
    sample_extent = diagonal(sample_bounds)
    tile_size = 16
    n_tiles = Pnt2i(floor.((sample_extent .+ tile_size .- 1) ./ tile_size))
    total_tiles = n_tiles.x * n_tiles.y
    @info "RENDERING\n\tsample_bounds = $(sample_bounds)\n\tsample_extent = $(sample_extent)\n\tn_tiles = $n_tiles"
    print("Rendering " * num2str(total_tiles) * " tiles\n")

    prog = Progress(total_tiles)
    update!(prog,0)
    jj = Threads.Atomic{Int}(0)
    l = Threads.SpinLock()

    
    # for UGLY in 0:(n_tile.x * n_tile.y - 1)
    #     tile = Pnt2i(UGLY % n_tile.x, UGLY ÷ n_tile.y)
    #     @info "RENDERING: $tile"
    #     x0 = sample_bounds.pMin.x + tile.x * tile_size
    #     x1 = min(x0 + tile_size, sample_bounds.pMax.x)
    #     y0 = sample_bounds.pMin.y + tile.y * tile_size
    #     y1 = min(y0 + tile_size, sample_bounds.pMax.y)
    #     tile_bounds = Bounds2i(Pnt2i(x0, y0), Pnt2i(x1, y1))
    #     @info "RENDERING: Starting image tile $tile_bounds"
    #     for pixel in tile_bounds
    #         @info "RENDERING: $pixel" 
    #     end
    # end
    # @assert false

    print("Utilizing $(Threads.nthreads()) threads\n")
    Threads.@threads for k in 0:(total_tiles - 1)
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
        
        tile = Pnt2i(k % n_tiles.x, k ÷ n_tiles.x)
        seed::Int64 = tile.y * n_tiles.x + tile.x
        sampler = clone(i.sampler, seed)

        x0 = sample_bounds.pMin.x + tile.x * tile_size
        x1 = min(x0 + tile_size, sample_bounds.pMax.x)
        y0 = sample_bounds.pMin.y + tile.y * tile_size
        y1 = min(y0 + tile_size, sample_bounds.pMax.y)
        tile_bounds = Bounds2i(Pnt2i(x0, y0), Pnt2i(x1, y1))
        film_tile = FilmTile(i.camera.core.core.film, tile_bounds)
        for pixel in tile_bounds # adding iterator method is cool
            @info "WORKING ON PIXEL $pixel"
            for sample_index in 1:sampler.samples_per_pixel
                start_pixel_sample!(sampler, pixel, sample_index-1)
                camera_sample = get_camera_sample!(sampler, pixel)
                # @info "camera_sample: $camera_sample"
                ray, w = generate_ray_differential(i.camera, camera_sample)
                scale_differentials!(ray, 1.0 / sqrt(sampler.samples_per_pixel))
                L = spectrum_from_float(0.0)

                if w > 0
                    L = li(i, ray, scene, 0, sampler)
                end

                if any(isnan.(L))
                    L = spectrum_from_float(0.0)
                end
                # L = spectrum_from_float((Float64(pixel.x) * Float64(pixel.y))/(sample_bounds.pMax.x * sample_bounds.pMax.y))
                
                @info "FIN: Added sample $L @ $pixel"
                add_sample!(film_tile, camera_sample.film, L, w)
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
    mi::MediumInteraction,
    scene::Scene,
    sampler::AbstractSampler,
    light_distribution::Distribution1D,
    handle_media::Bool,
)::Spectrum
    light_num, light_pdf, _ = sample_discrete(light_distribution, get_1D!(sampler))
    light = scene.lights[light_num]
    u_light = get_2D!(sampler)
    u_scattering = get_2D!(sampler)
    return estimate_direct_medium(mi, u_scattering, light, u_light, scene, sampler, handle_media) / light_pdf
end

function estimate_direct_medium(
    mi::MediumInteraction,
    u_scattering::Pnt2,
    light::Light,
    u_light::Pnt2,
    scene::Scene,
    sampler::AbstractSampler,
    handle_media::Bool=true,
)::Spectrum
    Ld = spectrum_from_float(0.0)

    # Sample light source
    Li, wi, light_pdf, vis, _, _ = sample_li(light, mi.core, u_light)
    if (light_pdf > 0.0) && !is_black(Li)
        p_val = mi.phase(mi.core.wo, wi)
        f = spectrum_from_float(p_val)
        scattering_pdf = p_val
        if !is_black(f)
            if handle_media
                Li *= tr(vis, scene.b, sampler)
            else
                if !unoccluded(vis, scene.b)
                    Li = spectrum_from_float(0.0)
                end
            end
            if !is_black(Li)
                if is_delta_light(light)
                    Ld += f * Li / light_pdf
                else
                    weight = power_heuristic(1.0, light_pdf, 1.0, scattering_pdf)
                    Ld += f * Li * weight / light_pdf
                end
            end
        end
    end

    # Sample phase function for MIS
    if !is_delta_light(light)
        ps_p, ps_wi, ps_pdf = sample_p(mi.phase, mi.core.wo, u_scattering)
        f = spectrum_from_float(ps_p)
        scattering_pdf = ps_pdf
        if !is_black(f) && scattering_pdf > 0.0
            light_pdf = pdf_li(light, mi.core, ps_wi)
            (light_pdf == 0.0) && return Ld
            weight = power_heuristic(1.0, scattering_pdf, 1.0, light_pdf)

            ray = spawn_ray(mi.core, ps_wi)
            found_surface_interaction, _, light_isect = intersect!(scene.b, ray)
            Li = spectrum_from_float(0.0)
            if found_surface_interaction
                if !(light_isect.primitive.area_light isa Nothing)
                    Li = le(light_isect, -ps_wi)
                end
            else
                Li = le(light, ray)
            end
            if !is_black(Li)
                Ld += f * Li * weight / scattering_pdf
            end
        end
    end

    return Ld
end

function uniform_sample_one_light(
    isect::SurfaceInteraction,
    scene::Scene,
    sampler::AbstractSampler,
    light_distribution::Distribution1D,
    handle_media::Bool,
)::Spectrum
    # chose a single light to sample
    light_num, light_pdf, _ = sample_discrete(light_distribution, get_1D!(sampler))
    light = scene.lights[light_num]

    u_light = get_2D!(sampler)
    u_scattering = get_2D!(sampler)
    return estimate_direct(isect, u_scattering, light, u_light, scene, sampler, handle_media) / light_pdf
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
    # @info "EstimateDirect uLight: $u_light -> Li: $Li, wi: $wi, pdf: $light_pdf"
    if (light_pdf > 0.0) && (!is_black(Li))
        # compute BSDF or phase functions value for light sample
        # TODO: not checking for phase function, assuming is surface interaction
        if is_surface_interaction(isect)
            f = isect.bsdf(isect.core.wo, wi, bsdf_flags) * abs(dot(wi, isect.shading.n))
            scattering_pdf = compute_pdf(isect.bsdf, isect.core.wo, wi, bsdf_flags)
            # @info "  surf f*dot : $f, scatteringPdf: $scattering_pdf"
        else
            @assert false
        end

        if !is_black(f)
            # compute effect of visibility for light source sample
            if handle_media
                Li *= tr(vis, scene.b, sampler)
                # @info "  after Tr, Li: $Li"
            else
                if !unoccluded(vis, scene.b)
                    Li = spectrum_from_float(0.0)
                    # @info "  shadow ray blocked"
                else
                    # @info "  shadow ray unoccluded"
                end
            end

            # add light's contribution to reflected radiance
            if !is_black(Li)
                if is_delta_light(light)
                    Ld += f * Li / light_pdf
                else
                    weight = power_heuristic(1.0, light_pdf, 1.0, scattering_pdf)
                    Ld += f * Li * weight / light_pdf
                end
            end
        end
    end

    # sampling BSDF with multiple importance sampling
    if !is_delta_light(light)
        sampled_specular = false
        if is_surface_interaction(isect)
            # sample scattered direction for surface interaction
            wi, f, scattering_pdf, sampled_type = sample_f(isect.bsdf, isect.core.wo, u_scattering, bsdf_flags)
            f *= abs(dot(wi, isect.shading.n))
            sampled_specular = sampled_type & BSDF_SPECULAR == sampled_type
        else
            @assert false
        end
        # @info "  BSDF / phase sampling f: $f, scatteringPdf: $scattering_pdf"

        # ASSUMING IS NOT BLACK
        if (!is_black(f) && (scattering_pdf > 0.0))
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

            # @info "TR: $Tr"

            # add light contribution from material sampling
            Li = spectrum_from_float(0.0)
            if found_surface_interaction
                if !(light_isect.primitive.area_light isa Nothing)
                    Li = le(light_isect, -wi)
                    # @info "Li: $Li"
                end
            else
                Li = le(light, ray)
                # @info "Li: $Li"
            end
            # IF NOT BLACK
            if !is_black(Li)
                Ld += f * Li * Tr * weight / scattering_pdf
                # @info "Ld: $Ld"
            end
        end
    end
    return Ld
end
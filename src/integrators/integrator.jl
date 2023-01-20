function render(i::Union{WhittedIntegrator, PathIntegrator}, scene::Scene, minimal::Bool=false)
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
        x, y = k % width, k ÷ width
        tile = Pnt2(x, y)
        k_sampler = deepcopy(i.sampler)

        tb_min = sample_bounds.pMin .+ tile .* tile_size
        tb_max = min.(tb_min .+ (tile_size - 1), sample_bounds.pMax)
        tile_bounds = Bounds2(tb_min, tb_max)
        film_tile = FilmTile(i.camera.core.core.film, tile_bounds)
        for pixel in tile_bounds # adding iterator method is cool
            start_pixel!(k_sampler, pixel)
            while has_next_sample(k_sampler)
                camera_sample = get_camera_sample!(k_sampler, pixel)
                ray, w = generate_ray_differential(i.camera, camera_sample)
                scale_differentials!(ray, 1.0 / sqrt(k_sampler.pixel_sampler.sampler.samples_per_pixel))
                L = Spectrum(0)

                if minimal
                    check, t, interaction, = intersect!(scene.b, ray)
                    if check
                        L = Spectrum(interaction.primitive.material.Kd(interaction))
                    else
                        L = Spectrum(0)
                    end
                else
                    if w > 0
                        L = li(i, ray, scene, 0)
                    end
                end

                if any(isnan.(L))
                    L = Spectrum(0)
                end

                add_sample!(film_tile, camera_sample.film, L, 1.0)

                start_next_sample!(k_sampler)
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
    save(got_film)
end

function uniform_sample_one_light(isect::SurfaceInteraction, scene::Scene, sampler::AbstractSampler, handle_media::Bool=false)::Spectrum
    # randomly chose a single light to sample
    n_lights = length(scene.lights)   
    (n_lights==0) && return Spectrum(0)
    light_num = Int(floor(rand()*n_lights)+1)
    light = scene.lights[light_num]

    u_light = get_2D!(sampler)
    u_scattering = get_2D!(sampler)
    return n_lights * estimate_direct(isect, u_scattering, light, u_light, scene, sampler, handle_media, false)
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
    Ld = Spectrum(0)
    
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
                Li = Spectrum(0)
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
        Tr = Spectrum(1,1,1)
        # assuming no media to handle
        found_surface_interaction, t, light_isect = intersect!(scene.b, ray)

        # add light contribution from material sampling
        Li = Spectrum(0)
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
struct WhittedIntegrator <: AbstractIntegrator
    camera::C where C <: Camera
    sampler::S where S <: AbstractSampler
    max_depth::Int64
end


function render(i::WhittedIntegrator, scene::Scene)
    sample_bounds = get_sample_bounds(get_film(i.camera))
    sample_extent = diagonal(sample_bounds)
    tile_size = 16
    width, height = Int64.(floor.((sample_extent .+ tile_size) ./ tile_size))
    total_tiles = width * height - 1
    print("Rendering $(total_tiles + 1) tiles\n")

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
        film_tile = FilmTile(get_film(i.camera), tile_bounds)
        for pixel in tile_bounds # adding iterator method is cool
            start_pixel!(k_sampler, pixel)
            while has_next_sample(k_sampler)
                camera_sample = get_camera_sample!(k_sampler, pixel)
                ray, w = generate_ray_differential(i.camera, camera_sample)
                scale_differentials!(ray, 1.0 / sqrt(k_sampler.samples_per_pixel))
                L = Spectrum(0,0,0)

                # BEGIN
                if w > 0
                    L = li(i, ray, scene)
                end

                # check, t, interaction, = Intersect!(scene.b, ray)
                # if check
                #     L = Spectrum(interaction.primitive.material.Kd(interaction))
                # else
                #     L = Spectrum(0,0,0)
                # end

                add_sample!(film_tile, camera_sample.film, L, 1.0)

                start_next_sample!(k_sampler)
            end
        end
        merge_film_tile!(get_film(i.camera) , film_tile)
        # print("$(k)\n")
        Threads.atomic_add!(jj,1)
        Threads.lock(l)
        update!(prog, jj[])
        Threads.unlock(l)
    end
    save(get_film(i.camera))
end


function li(i::WhittedIntegrator, ray::AbstractRay, scene::Scene, depth::Int64=1)::Spectrum
    L = Spectrum(0, 0, 0)
    check, t, interaction = Intersect!(scene.b, ray)
    # if nothing is hit --> this is only for env light.
    if !check
        for light in scene.lights
            L += le(light, ray)
        end
        return L
    end

    # compute scattering functions at surface
    compute_scattering!(interaction, ray)
    if interaction.bsdf isa Nothing
        return li(spawn_ray(interaction.core, ray.direction), scene, i.sampler, depth)
    end

    # initialize after computing scattering, ughhhhhhhhhhhhhhhh
    n = interaction.shading.n
    wo = interaction.core.wo 

    # if hit an area light, compute emitted ray
    # L += le(interaction, wo)

    # for each light source, add contrib
    for light in scene.lights
        sampled_li, wi, pdf, visibility_tester = sample_li(light, interaction.core, get_2D!(i.sampler))   
        if pdf == 0
            continue
        end
        f = interaction.bsdf(wo, wi)
        if unoccluded(visibility_tester, scene.b)
            L += f .* sampled_li * abs(dot(wi, n)) / pdf
        end
    end

    if depth + 1 <= i.max_depth
        L += specular_reflect(i, ray, interaction, scene, depth)
        L += specular_transmit(i, ray, interaction, scene, depth)
    end
    return L
end


function specular_reflect(i::WhittedIntegrator, ray::AbstractRay, surface_interaction::SurfaceInteraction, scene::Scene, depth::Int64)
    wo = surface_interaction.core.wo
    type = BSDF_REFLECTION | BSDF_SPECULAR
    wi, f, pdf, sampled_type = sample_f(surface_interaction.bsdf, wo, get_2D!(i.sampler), type)

    ns = surface_interaction.shading.n
    if pdf == 0 || abs(dot(wi, ns)) == 0
        return Spectrum(0, 0, 0)
    end

    ray = spawn_ray(interaction.core, wi)
    return f .* li(i, ray, scene, depth + 1) * abs(dot(wi, ns)) / pdf
end

function specular_transmit(i::WhittedIntegrator, ray::AbstractRay, surface_interaction::SurfaceInteraction, scene::Scene, depth::Int64)
    wo = surface_interaction.core.wo
    type = BSDF_TRANSMISSION | BSDF_SPECULAR
    wi, f, pdf, sampled_type = sample_f(surface_interaction.bsdf, wo, get_2D!(i.sampler), type)

    ns = surface_interaction.shading.n
    if pdf == 0 || abs(dot(wi, ns)) == 0
        return Spectrum(0, 0, 0)
    end

    ray = spawn_ray(interaction.core, wi)
    eta = 1/ surface_interaction.bsdf.eta

    if dot(ns,ns) < 0
        eta = 1/eta
        ns = -ns
    end

    return f * li(i, ray, scene, depth+1) * abs(dot(wi,ns)) / pdf
end
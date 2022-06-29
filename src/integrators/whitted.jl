struct WhittedIntegrator <: AbstractIntegrator
    camera::C where C <: Camera
    sampler::S where S <: AbstractSampler
    max_depth::Int64
end


function render(i::WhittedIntegrator, BVH::BVHNode)
    sample_bounds = get_sample_bounds(get_film(i.camera))
    sample_extent = diagonal(sample_bounds)
    tile_size = 160
    width, height = Int64.(floor.((sample_extent .+ tile_size) ./ tile_size))
    total_tiles = width * height - 1
    print("Rendering $(total_tiles + 1) tiles\n")

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
                camera_sample = get_camera_sample(k_sampler, pixel)
                ray, _ = generate_ray(i.camera, camera_sample)

                # dumy code for now
                check, t, interaction = Intersect(BVH, ray)
                if check
                    L = Spectrum(interaction.primitive.material.Kd.value)
                else
                    L = Spectrum(0, 0, 0)
                end

                add_sample!(film_tile, camera_sample.film, L, 1.0)

                start_next_sample!(k_sampler)
            end
        end
        merge_film_tile!(get_film(i.camera) , film_tile)
    end
    save(get_film(i.camera))
end
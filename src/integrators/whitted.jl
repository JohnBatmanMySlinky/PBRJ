struct WhittedIntegrator <: AbstractIntegrator
    camera::C where C <: Camera
    sampler::S where S <: AbstractSampler
    max_depth::Int64
end


function render(i::WhittedIntegrator)
    sample_bounds = get_sample_bounds(get_film(i.camera))
    sample_extent = diagonal(sample_bounds)
    tile_size = 160
    width, height = Int64.(floor.((sample_extent .+ tile_size) ./ tile_size))
    total_tiles = width * height - 1
    print("Rendering $(total_tiles + 1) tiles\n")

    print("Utilizing $(Threads.nthreads()) threads\n")
    Threads.@threads for k in 0:total_tiles
        x, y = k % width, k / width
        tile = Pnt2(x, y)
        t_sampler = deepcopy(i.sampler)

        tb_min = sample_bounds.pMin .+ tile .* tile_size
        tb_max = min.(tb_min .+ (tile_size - 1), sample_bounds.pMax)
        tile_bounds = Bounds2(tb_min, tb_max)

        print("Tile Bounds\n")
        print(tile_bounds)
        print("\n\n")
    end
end
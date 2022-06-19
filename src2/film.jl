mutable struct Pixel
    xyz::Vec3
    filter_weight_sum::Float32
    splat_xyz::Vec3
end

struct Film
    resolution::Vec2
    crop_bounds::Bounds2
    diagonal::Float64
    filter::F
    filename::String
    pixels::Matrix{Pixel}
    filter_table_width::Int32
    filter_table::Matrix{Float64}
    scale::Float32

    function Film(
        resolution::Vec2,
        crop_bounds::Bounds2,
        filter::Filter,
        diagonal::Float64,
        scale::Float64,
        filename::String,
    )
        filter_table_width = 16
        filter_table = Matrix{Float32}(undef, filter_table_width, filter_table_width)
        crop_bounds = Bounds2(
            ceil.(resolution .* crop_bounds.p_min) .+ 1,
            ceil.(resolution .* crop_bounds.p_max),
        )
        crop_resolution = inclusive_sides(crop_bounds)
        # Allocate film image storage.
        pixels = Pixel[
            Pixel(Vec3(0, 0, 0), 0, Vec3(0, 0, 0))
            for y in 1:crop_resolution[end], x in 1:crop_resolution[begin]
        ]
        # Precompute filter weight table.
        r = filter.radius ./ filter_table_width
        for y in 0:filter_table_width - 1, x in 0:filter_table_width - 1
            p = Vec2((x + 0.5) * r[1], (y + 0.5) * r[2])
            filter_table[y + 1, x + 1] = filter(p)
        end
        new(
            resolution, crop_bounds, diagonal * 0.001, filter, filename,
            pixels, filter_table_width, filter_table, scale,
        )
    end
end

function get_sample_bounds(f::Film)
    return Bounds2(
        floor.(f.crop_bounds.pMin .+ 0.5 .- f.filter.radius),
        ceil.(f.crop_bounds.pMax .- 0.5 .+ f.filter.radius),
    )
end

function get_physical_extension(f::Film)
    aspect = f.resolution[2] / f.resolution[1]
    x = sqrt(f.diagonal ^ 2 / (1 + aspect ^ 2))
    y = aspect * x
    return Bounds2(Vec2(-x / 2, -y / 2), Vec2(x / 2, y / 2))
end

mutable struct FilmTilePixel
    contrib_sum::Vec3
    filter_weight_sum::Float64
end
FilmTilePixel() = FilmTilePixel(Vec3(0,0,0), 0)

struct FilmTile
    bounds::Bounds2
    filter_radius::Vec2
    inv_filter_radius::Vec2
    filter_table::Matrix{Float64}
    filter_table_width::Int64
    pixels::Matrix{FilmTilePixel}

    function FilmTile(
        bounds::Bounds2, filter_radius::Vec2,
        filter_table::Matrix{Float64}, filter_table_width::Int64,
    )
        tile_res = inclusive_sides(bounds)
        pixels = [FilmTilePixel() for _ in 1:tile_res[2], __ in 1:tile_res[1]]
        new(
            bounds, filter_radius, 1 ./ filter_radius,
            filter_table, filter_table_width,
            pixels,
        )
    end
end

function FilmTile(f::Film, sample_bounds::Bounds2)
    p0 = ceil.(sample_bounds.p_min .- 0.5 .- f.filter.radius)
    p1 = floor.(sample_bounds.p_max .- 0.5 .+ f.filter.radius) .+ 1
    tile_bounds = Bounds2(p0, p1) ∩ f.crop_bounds
    return FilmTile(tile_bounds, f.filter.radius, f.filter_table, f.filter_table_width)
end

function add_sample!(t::FilmTile, point::Vec2, spectrum::Vec3, sample_weight::Float32 = 1)
    discrete_point = point .- 0.5
    p0 = ceil.(discrete_point .- t.filter_radius)
    p1 = floor.(discrete_point .+ t.filter_radius) .+ 1
    p0 = max.(p0, max.(t.bounds.pMax, Vec2(1, 1)))
    p1 = min.(p1, t.bounds.pMax)
    # Precompute x & y filter offsets.
    offsets_x = Vector{Int64}(undef, p1[1] - p0[1] + 1)
    offsets_y = Vector{Int64}(undef, p1[2] - p0[2] + 1)
    for (i, x) in enumerate(p0[1]:p1[1])
        fx = abs((x - discrete_point[1]) * t.inv_filter_radius[1] * t.filter_table_width)
        offsets_x[i] = clamp(ceil(fx), 1, t.filter_table_width)  # TODO is clipping ok?
    end
    for (i, y) in enumerate(p0[2]:p1[2])
        fy = abs((y - discrete_point[2]) * t.inv_filter_radius[2] * t.filter_table_width)
        offsets_y[i] = clamp(floor(fy), 1, t.filter_table_width)
    end
    # Loop over filter support & add sample to pixel array.
    for (j, y) in enumerate(p0[2]:p1[2]), (i, x) in enumerate(p0[1]:p1[1])
        w = t.filter_table[offsets_y[j], offsets_x[i]]
        pixel = get_pixel(t, Vec2(x, y))
        @assert sample_weight <= 1
        @assert w <= 1
        pixel.contrib_sum += spectrum * sample_weight * w
        pixel.filter_weight_sum += w
    end
end

function get_pixel(t::FilmTile, p::Vec2)
    pp = (p .- t.bounds.p_min .+ 1)
    return t.pixels[pp[2], pp[1]]
end

function get_pixel(f::Film, p::Vec2)
    pp = (p .- f.crop_bounds.p_min .+ 1)
    return f.pixels[pp[2], pp[1]]
end

function merge_film_tile!(f::Film, ft::FilmTile)
    x_range = ft.bounds.p_min[1]:ft.bounds.p_max[1]
    y_range = ft.bounds.p_min[2]:ft.bounds.p_max[2]

    for y in y_range, x in x_range
        pixel = Vec2(x, y)
        tile_pixel = get_pixel(ft, pixel)
        merge_pixel = get_pixel(f, pixel)
        merge_pixel.xyz += to_XYZ(tile_pixel.contrib_sum)
        merge_pixel.filter_weight_sum += tile_pixel.filter_weight_sum
    end
end

function set_image!(f::Film, spectrum::Matrix{Vec3})
    @assert size(f.pixels) == size(spectrum)
    for (i, p) in enumerate(f.pixels)
        p.xyz = to_XYZ(spectrum[i])
        p.filter_weight_sum = 1
        p.splat_xyz = Vec3(0)
    end
end

function save(film::Film, splat_scale::Float32 = 1)
    image = Array{Float64}(undef, size(film.pixels)..., 3)
    for y in 1:size(film.pixels)[1], x in 1:size(film.pixels)[2]
        pixel = film.pixels[y, x]
        image[y, x, :] .= XYZ_to_RGB(pixel.xyz)
        filter_weight_sum = pixel.filter_weight_sum
        if filter_weight_sum != 0
            inv_weight = 1 / filter_weight_sum
            image[y, x, :] .= max.(0, image[y, x, :] .* inv_weight)
        end
        # Add splat value at pixel & scale.
        splat_rgb = XYZ_to_RGB(pixel.splat_xyz)
        image[y, x, :] .+= splat_scale .* splat_rgb
        image[y, x, :] .*= film.scale
    end
    clamp!(image, 0, 1) # TODO remap instead of clamping?
    FileIO.save(film.filename, image[end:-1:begin, :, :])
end
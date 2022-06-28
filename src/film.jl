mutable struct Pixel
    xyz::Pnt3
    filter_weight_sum::Float64
    splat_xyz::Pnt3
end

# PBR 7.9.1
struct Film
    # overall resolution in pixels
    full_resolution::Pnt2

    # crop window to specify subset of image to render
    # in [0,1] range
    cropped_pixel_bounds::Bounds2

    # length of the diagonal of the films physical area in mm
    diagonal::Float64

    # filter function
    filter::F where F <: Filter

    # filename
    filename::String
    pixels::Matrix{Pixel}
    filter_table_width::Int64
    filter_table::Matrix{Float64}
    scale::Float64

    function Film(
        full_resolution::Pnt2,
        cropped_pixel_bounds::Bounds2,
        filter::F,
        diagonal::Float64,
        scale::Float64,
        filename::String
    ) where F <: Filter
        filter_table_width = 16
        filter_table = Matrix{Float64}(undef, filter_table_width, filter_table_width)

        # compute image bounds
        cropped_pixel_bounds = Bounds2(
            ceil.(full_resolution .* cropped_pixel_bounds.pMin) .+ 1.0,
            ceil.(full_resolution .* cropped_pixel_bounds.pMax)
        )
        cropped_resolution = inclusive_sides(cropped_pixel_bounds)


        # allocate film image storage
        pixels = Pixel[
            Pixel(Pnt3(0, 0, 0), 0, Pnt3(0, 0, 0)) for y in 1:cropped_resolution[end], x in 1:cropped_resolution[begin]
        ]

        # precompute filter weight table
        r = filter.radius ./ filter_table_width
        for y in 0:filter_table_width - 1
            for x in 0:filter_table_width - 1
                p = Pnt2((x + 0.5) * r[1], (y + 0.5) * r[2])
                filter_table[y+1,x+1] = filter(p)
            end
        end

        new(
            full_resolution,
            cropped_pixel_bounds,
            diagonal * .001, # convert milimeters to meters
            filter,
            filename,
            pixels,
            filter_table_width,
            filter_table,
            scale
        )
    end
end

########################################
######## Misc ##########################
########################################
function get_sample_bounds(f::Film)
    return Bounds2(
        floor.(f.cropped_pixel_bounds.pMin .+ 0.5 .- f.filter.radius),
        ceil.(f.cropped_pixel_bounds.pMax .- 0.5 .+ f.filter.radius),
    )
end

function get_pixel(f::Film, p::Pnt2)
    pp = Int32.(p .- f.cropped_pixel_bounds.pMin .+ 1.0)
    return f.pixels[pp[2], pp[1]]
end

# PBR 7.9.2
mutable struct FilmTilePixel
    contrib_sum::Spectrum
    filter_weight_sum::Float64
end

struct FilmTile
    pixel_bounds::Bounds2
    filter_radius::Pnt2
    inv_filter_radius::Pnt2
    filter_table::Matrix{Float32}
    filter_table_width::Int32
    pixels::Matrix{FilmTilePixel}

    function FilmTile(f::Film, sample_bounds::Bounds2)
        p0 = ceil.(sample_bounds.pMin .- 0.5 .- f.filter.radius)
        p1 = floor.(sample_bounds.pMax .- 0.5 .+ f.filter.radius) .+ 1.0
        pixel_bounds = intersection(Bounds2(p0, p1), f.cropped_pixel_bounds)
        tile_res = Int32.(inclusive_sides(pixel_bounds))
        pixels = [FilmTilePixel(Spectrum(0, 0, 0), 0) for _ in 1:tile_res[2], __ in 1:tile_res[1]]

        new(
            pixel_bounds, 
            f.filter.radius, 
            1 ./ f.filter.radius,
            f.filter_table, 
            f.filter_table_width,
            pixels,
        )
    end 
end

function get_pixel(t::FilmTile, p::Pnt2)
    pp = Int32.(p .- t.pixel_bounds.pMin .+ 1f0)
    return t.pixels[pp[2], pp[1]]
end

function add_sample!(t::FilmTile, point::Pnt2, spectrum::S, sample_weight::Float64 = 1,) where S <: Spectrum
    # Compute sample's raster bounds.
    discrete_point = point .- 0.5
    p0 = ceil.(discrete_point .- t.filter_radius)
    p1 = floor.(discrete_point .+ t.filter_radius) .+ 1
    p0 = max.(p0, max.(t.pixel_bounds.pMin, Pnt2(1,1)))
    p1 = min.(p1, t.pixel_bounds.pMax)   
    # Precompute x & y filter offsets.
    offsets_x = Vector{Int32}(undef, Int32(p1[1] - p0[1] + 1))
    offsets_y = Vector{Int32}(undef, Int32(p1[2] - p0[2] + 1))
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
        pixel = get_pixel(t, Pnt2(x, y))
        @assert sample_weight <= 1
        @assert w <= 1
        pixel.contrib_sum += spectrum * sample_weight * w
        pixel.filter_weight_sum += w
    end
end

function merge_film_tile!(f::Film, ft::FilmTile)
    x_range = ft.pixel_bounds.pMin[1]:ft.pixel_bounds.pMax[1]
    y_range = ft.pixel_bounds.pMin[2]:ft.pixel_bounds.pMax[2]

    for y in y_range, x in x_range
        pixel = Pnt2(x, y)
        tile_pixel = get_pixel(ft, pixel)
        merge_pixel = get_pixel(f, pixel)
        merge_pixel.xyz += RGB_to_XYZ(tile_pixel.contrib_sum)
        merge_pixel.filter_weight_sum += tile_pixel.filter_weight_sum
    end
end

function save(film::Film, splat_scale::Float32 = 1)
    image = Array{Float32}(undef, size(film.pixels)..., 3)
    for y in 1:size(film.pixels)[1], x in 1:size(film.pixels)[2]
        pixel = film.pixels[y, x]
        image[y, x, :] .= XYZ_to_RGB(pixel.xyz)
        # Normalize pixel with weight sum.
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
    clamp!(image, 0f0, 1f0) # TODO remap instead of clamping?
    FileIO.save(film.filename, image[end:-1:begin, :, :])
end
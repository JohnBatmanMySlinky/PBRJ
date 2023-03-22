mutable struct Pixel
    xyz::Pnt3
    filter_weight_sum::Float64
    splat_xyz::AtomicPnt3
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
            Pixel(Pnt3(0), 0, AtomicPnt3(0.0, 0.0, 0.0)) for y in 1:cropped_resolution[end], x in 1:cropped_resolution[begin]
        ]

        # precompute filter weight table
        for y in 0:(filter_table_width - 1)
            for x in 0:(filter_table_width - 1)
                p = Pnt2((x + 0.5) * filter.radius.x / filter_table_width, (y + 0.5) * filter.radius.y / filter_table_width)
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
    pp = Int64.(p .- f.cropped_pixel_bounds.pMin .+ 1.0)
    return f.pixels[pp.y, pp.x]
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
    filter_table::Matrix{Float64}
    filter_table_width::Int64
    pixels::Matrix{FilmTilePixel}

    function FilmTile(f::Film, sample_bounds::Bounds2)
        p0 = ceil.(sample_bounds.pMin .- 0.5 .- f.filter.radius)
        p1 = floor.(sample_bounds.pMax .- 0.5 .+ f.filter.radius) .+ 1.0
        pixel_bounds = intersection(Bounds2(p0, p1), f.cropped_pixel_bounds)
        tile_res = Pnt2(inclusive_sides(pixel_bounds))
        pixels = [FilmTilePixel(Spectrum(0, 0, 0), 0) for _ in 1:tile_res.y, __ in 1:tile_res.x]

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
    pp = Int64.(p .- t.pixel_bounds.pMin .+ 1)
    return t.pixels[pp.y, pp.x]
end

function add_sample!(t::FilmTile, point::Pnt2, spectrum::S, sample_weight::Float64 = 1.0) where S <: Spectrum
    # Compute sample's raster bounds.
    discrete_point = point .- 0.5
    p0 = ceil.(discrete_point .- t.filter_radius)
    p1 = floor.(discrete_point .+ t.filter_radius) .+ 1
    p0 = max.(p0, max.(t.pixel_bounds.pMin, Pnt2(1,1)))
    p1 = min.(p1, t.pixel_bounds.pMax)   

    # Precompute x & y filter offsets.
    offsets_x = Vector{Int64}(undef, Int(p1.x - p0.x + 1))
    offsets_y = Vector{Int64}(undef, Int(p1.y - p0.y + 1))
    for (i, x) in enumerate(p0.x:p1.x)
        fx = abs((x - discrete_point.x) * t.inv_filter_radius.x * t.filter_table_width)
        offsets_x[i] = clamp(ceil(fx), 1, t.filter_table_width)  # TODO is clipping ok?
    end
    for (i, y) in enumerate(p0.y:p1.y)
        fy = abs((y - discrete_point.y) * t.inv_filter_radius.y * t.filter_table_width)
        offsets_y[i] = clamp(floor(fy), 1, t.filter_table_width)
    end
    # Loop over filter support & add sample to pixel array.
    for (j, y) in enumerate(p0.y:p1.y)
        for (i, x) in enumerate(p0.x:p1.x)
            w = t.filter_table[offsets_y[j], offsets_x[i]]
            pixel = get_pixel(t, Pnt2(x, y))
            @assert sample_weight <= 1
            @assert w <= 1
            pixel.contrib_sum += spectrum * sample_weight * w
            pixel.filter_weight_sum += w
        end
    end
end

function merge_film_tile!(f::Film, ft::FilmTile)
    for y in ft.pixel_bounds.pMin.y:ft.pixel_bounds.pMax.y
        for x in ft.pixel_bounds.pMin.x:ft.pixel_bounds.pMax.x
            pixel = Pnt2(x, y)
            tile_pixel = get_pixel(ft, pixel)
            merge_pixel = get_pixel(f, pixel)
            merge_pixel.xyz += RGB_to_XYZ(convert(Spectrum, tile_pixel.contrib_sum))
            merge_pixel.filter_weight_sum += tile_pixel.filter_weight_sum
        end
    end
end

function add_splat!(f::Film, p::Pnt2, v::Spectrum)
    pp = trunc.(p)
    (!inside_exclusive(pp, f.cropped_pixel_bounds)) && (return )
    pixel = get_pixel(f, pp)
    Threads.atomic_add!(pixel.splat_xyz, RGB_to_XYZ(v))
end

function save(film::Film, render_pass_flag::UInt8, splat_scale::Float64 = 1.0)::Array{Float64}
    X, Y = size(film.pixels)
    image = Array{Float64}(undef, X, Y, 3)
    for y in 1:Y
        for x in 1:X
            pixel = film.pixels[y, x]
            image[y, x, :] .= XYZ_to_RGB(pixel.xyz)
            # Normalize pixel with weight sum.
            filter_weight_sum = pixel.filter_weight_sum
            if filter_weight_sum != 0
                inv_weight = 1 / filter_weight_sum
                image[y, x, :] .= max.(0, image[y, x, :] .* inv_weight)
            end
            # Add splat value at pixel & scale.
            splat_rgb = XYZ_to_RGB(convert(Pnt3, pixel.splat_xyz))
            image[y, x, :] .+= splat_scale .* splat_rgb
            image[y, x, :] .*= film.scale
        end
    end
    # normalize depth and position pass to be [0,1]
    # also need make sure 0-1 not 1-0
    # if (render_pass_flag == 2) || (render_pass_flag == 4) 
    if (render_pass_flag == 2) || (render_pass_flag == 4)
        max_depth = maximum(image)
        min_depth = minimum(image)
        image .-= max_depth
        image ./= (min_depth - max_depth)
    end
    clamp!(image, 0.0, 1.0)
    return image[end:-1:begin, :, :]
end
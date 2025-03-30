mutable struct PassPixel
    # These three fields are a copy from Pixel
    xyz::XYZPBRT
    filter_weight_sum::Float64
    splat_xyz::AtomicXYZPBRT

    # additional fields needed for edge avoiding a-trous filter
    albedo::XYZPBRT                 # albedo
    depth::XYZPBRT                  # depth
    normal::XYZPBRT                 # normal
    position::XYZPBRT               # position

    function PassPixel()
        return new(
            XYZPBRT(0.0, 0.0, 0.0),
            0.0,
            AtomicXYZPBRT(0.0, 0.0, 0.0),
            XYZPBRT(0.0, 0.0, 0.0),
            XYZPBRT(0.0, 0.0, 0.0),
            XYZPBRT(0.0, 0.0, 0.0),
            XYZPBRT(0.0, 0.0, 0.0)
        )
    end
end

struct PassFilm
    # overall resolution in pixels
    full_resolution::Pnt2i

    # crop window to specify subset of image to render
    # in [0,1] range
    cropped_pixel_bounds::Bounds2

    # length of the diagonal of the films physical area in mm
    diagonal::Float64

    # filter function
    filter::F where F <: Filter

    # filename
    filename::String
    pixels::Matrix{PassPixel}
    filter_table_width::Int64
    filter_table::Matrix{Float64}
    scale::Float64

    function PassFilm(
        full_resolution::Pnt2i,
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
            ceil.(full_resolution .* cropped_pixel_bounds.pMin),
            ceil.(full_resolution .* cropped_pixel_bounds.pMax)
        )
        cropped_resolution = inclusive_sides(cropped_pixel_bounds)


        # allocate film image storage
        pixels = PassPixel[
            PassPixel() for y in 1:cropped_resolution[end], x in 1:cropped_resolution[begin]
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

function FilmTile(f::PassFilm, sample_bounds::Bounds2i)::FilmTile
    p0::Pnt2i = ceil.(sample_bounds.pMin .- 0.5 .- f.filter.radius)
    p1::Pnt2i = floor.(sample_bounds.pMax .- 0.5 .+ f.filter.radius) .+ 1
    pixel_bounds::Bounds2i = intersection(Bounds2i(p0, p1), f.cropped_pixel_bounds)
    pixels = [FilmTilePixel(spectrum_from_float(0.0, 0.0, 0.0), 0) for _ in 1:f.filter_table_width, __ in 1:f.filter_table_width]

    return FilmTile(
        pixel_bounds, 
        f.filter.radius, 
        1 ./ f.filter.radius,
        f.filter_table, 
        f.filter_table_width,
        pixels,
    )
end 

function get_sample_bounds(f::PassFilm)::Bounds2i
    return Bounds2i(
        floor.(f.cropped_pixel_bounds.pMin .+ 0.5 .- f.filter.radius),
        ceil.(f.cropped_pixel_bounds.pMax .- 0.5 .+ f.filter.radius),
    )
end

function get_pixel(f::PassFilm, p::Pnt2i)::PassPixel
    pp = p .- f.cropped_pixel_bounds.pMin .+ 1
    return f.pixels[pp.y, pp.x]
end

function merge_film_tile!(f::PassFilm, ft::FilmTile)
    for y in ft.pixel_bounds.pMin.y:ft.pixel_bounds.pMax.y
        for x in ft.pixel_bounds.pMin.x:ft.pixel_bounds.pMax.x
            pixel = Pnt2i(x, y)
            tile_pixel = get_pixel(ft, pixel)
            merge_pixel = get_pixel(f, pixel)
            @info "merge_film_tile: Spectrum - $(tile_pixel.contrib_sum), XYZ - $(to_XYZ(tile_pixel.contrib_sum))"
            merge_pixel.xyz += to_XYZ(tile_pixel.contrib_sum)
            merge_pixel.filter_weight_sum += tile_pixel.filter_weight_sum
        end
    end
end

function add_splat!(f::PassFilm, p::Pnt2, v::Spectrum)
    pp = Pnt2i(trunc.(p))
    (!inside_exclusive(pp, f.cropped_pixel_bounds)) && (return )
    # JOHN HACK LUMINANCE CHECK
    pixel = get_pixel(f, pp)
    Threads.atomic_add!(pixel.splat_xyz, to_XYZ(v))
end

function save(film::PassFilm, splat_scale::Float64 = 1.0)::Array{Float64}

    # JOHN HACKS
    # only splat for full pass
    # filter weight sum is based off of full so I think I am improperly weighting...

    X, Y = size(film.pixels)
    pass = 5 # full, albedo, depth, normal, position
    image = Array{Float64}(undef, pass, X, Y, 3)
    for y in 1:Y
        for x in 1:X
            pixel = film.pixels[y, x]

            #################
            ### full pass ###
            #################
            image[1, y, x, :] .= XYZ_to_RGB(pixel.xyz)
            # Normalize pixel with weight sum.
            filter_weight_sum = pixel.filter_weight_sum
            if filter_weight_sum != 0
                image[1, y, x, :] .= max.(0, image[1, y, x, :] ./ filter_weight_sum)
            end
            # Add splat value at pixel & scale.
            @info "save: AtomicXYZ - $(pixel.splat_xyz), XYZ - $(convert(XYZPBRT, pixel.splat_xyz)), RGB - $(XYZ_to_RGB(convert(XYZPBRT, pixel.splat_xyz)))"
            splat_rgb = XYZ_to_RGB(convert(XYZPBRT, pixel.splat_xyz))
            image[1, y, x, :] .+= splat_scale .* splat_rgb
            image[1, y, x, :] .*= film.scale

            ###################
            ### albedo pass ###
            ###################
            image[2, y, x, :] .= XYZ_to_RGB(pixel.albedo)

            ##################
            ### depth pass ###
            ##################
            image[3, y, x, :] .= XYZ_to_RGB(pixel.depth)

            ###################
            ### normal pass ###
            ###################
            image[4, y, x, :] .= XYZ_to_RGB(pixel.normal)

            #####################
            ### position pass ###
            #####################
            image[5, y, x, :] .= XYZ_to_RGB(pixel.position)
        end
    end
    # normalize depth and position pass to be [0,1]
    # also need make sure 0-1 not 1-0
    # depth
    max_depth = maximum(image[2, :, :, :])
    min_depth = minimum(image[2, :, :, :])
    image[2, :, :, :] .-= max_depth
    image[2, :, :, :] ./= (min_depth - max_depth)

    # position
    for dim in 1:3
        max_depth = maximum(image[5, :, :, dim])
        min_depth = minimum(image[5, :, :, dim])
        image[5, :, :, dim] .-= max_depth
        image[5, :, :, dim] ./= (min_depth - max_depth)
    end

    clamp!(image, 0.0, 1.0)
    return image
end
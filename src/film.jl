mutable struct Pixel
    xyz::XYZPBRT
    filter_weight_sum::Float64
    splat_xyz::AtomicXYZPBRT

    function Pixel()
        return new(
            XYZPBRT(0.0, 0.0, 0.0),
            0.0,
            AtomicXYZPBRT(0.0, 0.0, 0.0)
        )
    end
end

mutable struct PassPixel
    # These three fields are a copy from Pixel
    xyz::XYZPBRT
    filter_weight_sum::Float64
    splat_xyz::AtomicXYZPBRT

    # additional fields needed for edge avoiding a-trous filter
    albedo::XYZPBRT                 # albedo
    depth::Float64                  # depth
    normal::XYZPBRT                 # normal
    position::XYZPBRT               # position

    function PassPixel()
        return new(
            XYZPBRT(0.0, 0.0, 0.0),
            0.0,
            AtomicXYZPBRT(0.0, 0.0, 0.0),
            XYZPBRT(0.0, 0.0, 0.0),
            0.0,
            XYZPBRT(0.0, 0.0, 0.0),
            XYZPBRT(0.0, 0.0, 0.0)
        )
    end
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
            Pixel() for y in 1:cropped_resolution[end], x in 1:cropped_resolution[begin]
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

struct PassFilm
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
    pixels::Matrix{PassPixel}
    filter_table_width::Int64
    filter_table::Matrix{Float64}
    scale::Float64

    function PassFilm(
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

########################################
######## Misc ##########################
########################################
function get_sample_bounds(f::Union{Film, PassFilm})::Bounds2
    return Bounds2(
        floor.(f.cropped_pixel_bounds.pMin .+ 0.5 .- f.filter.radius),
        ceil.(f.cropped_pixel_bounds.pMax .- 0.5 .+ f.filter.radius),
    )
end

function get_pixel(f::Film, p::Pnt2)::Pixel
    pp = Int64.(p .- f.cropped_pixel_bounds.pMin .+ 1.0)
    return f.pixels[pp.y, pp.x]
end

function get_pixel(f::PassFilm, p::Pnt2)::PassPixel
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

    function FilmTile(f::Union{Film,PassFilm}, sample_bounds::Bounds2)
        p0 = ceil.(sample_bounds.pMin .- 0.5 .- f.filter.radius)
        p1 = floor.(sample_bounds.pMax .- 0.5 .+ f.filter.radius) .+ 1.0
        pixel_bounds = intersection(Bounds2(p0, p1), f.cropped_pixel_bounds)
        tile_res = Pnt2(inclusive_sides(pixel_bounds))
        pixels = [FilmTilePixel(spectrum_from_float(0.0, 0.0, 0.0), 0) for _ in 1:tile_res.y, __ in 1:tile_res.x]

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

function merge_film_tile!(f::Union{Film, PassFilm}, ft::FilmTile)
    for y in ft.pixel_bounds.pMin.y:ft.pixel_bounds.pMax.y
        for x in ft.pixel_bounds.pMin.x:ft.pixel_bounds.pMax.x
            pixel = Pnt2(x, y)
            tile_pixel = get_pixel(ft, pixel)
            merge_pixel = get_pixel(f, pixel)
            @info "merge_film_tile: Spectrum - $(tile_pixel.contrib_sum), XYZ - $(to_XYZ(tile_pixel.contrib_sum))"
            merge_pixel.xyz += to_XYZ(tile_pixel.contrib_sum)
            merge_pixel.filter_weight_sum += tile_pixel.filter_weight_sum
        end
    end
end

function add_splat!(f::Union{Film, PassFilm}, p::Pnt2, v::Spectrum)
    pp = trunc.(p)
    (!inside_exclusive(pp, f.cropped_pixel_bounds)) && (return )
    # JOHN HACK LUMINANCE CHECK
    pixel = get_pixel(f, pp)
    Threads.atomic_add!(pixel.splat_xyz, to_XYZ(v))
end

function save(film::Film, splat_scale::Float64 = 1.0)::Array{Float64}
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
            @info "save: AtomicXYZ - $(pixel.splat_xyz), XYZ - $(convert(XYZPBRT, pixel.splat_xyz)), RGB - $(XYZ_to_RGB(convert(XYZPBRT, pixel.splat_xyz)))"
            splat_rgb = XYZ_to_RGB(convert(XYZPBRT, pixel.splat_xyz))
            image[y, x, :] .+= splat_scale .* splat_rgb
            image[y, x, :] .*= film.scale
        end
    end
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
            # Normalize pixel with weight sum.
            filter_weight_sum = pixel.filter_weight_sum
            if filter_weight_sum != 0
                image[2, y, x, :] .= max.(0, image[2, y, x, :] ./ filter_weight_sum)
            end

            ##################
            ### depth pass ###
            ##################
            image[3, y, x, :] .= RGBPBRT(pixel.depth, pixel.depth, pixel.depth)
            # Normalize pixel with weight sum.
            filter_weight_sum = pixel.filter_weight_sum
            if filter_weight_sum != 0
                image[3, y, x, :] .= max.(0, image[3, y, x, :] ./ filter_weight_sum)
            end

            ###################
            ### normal pass ###
            ###################
            image[4, y, x, :] .= XYZ_to_RGB(pixel.normal)
            # Normalize pixel with weight sum.
            filter_weight_sum = pixel.filter_weight_sum
            if filter_weight_sum != 0
                image[4, y, x, :] .= max.(0, image[4, y, x, :] ./ filter_weight_sum)
            end

            #####################
            ### position pass ###
            #####################
            image[5, y, x, :] .= XYZ_to_RGB(pixel.position)
            # Normalize pixel with weight sum.
            filter_weight_sum = pixel.filter_weight_sum
            if filter_weight_sum != 0
                image[5, y, x, :] .= max.(0, image[5, y, x, :] ./ filter_weight_sum)
            end

        end
    end
    # normalize depth and position pass to be [0,1]
    # also need make sure 0-1 not 1-0
    for pass in [2,4]
        max_depth = maximum(image[pass, :, :, :])
        min_depth = minimum(image[pass, :, :, :])
        image[pass, :, :, :] .-= max_depth
        image[pass, :, :, :] ./= (min_depth - max_depth)
    end
    clamp!(image, 0.0, 1.0)
    return image[:, end:-1:begin, :, :]
end
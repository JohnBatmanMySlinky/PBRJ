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

# PBR 7.9.1
struct Film
    full_resolution::Pnt2i
    cropped_pixel_bounds::Bounds2i
    diagonal::Float64
    filter::F where F <: Filter
    filename::String
    pixels::Vector{Pixel}
    filter_table_width::Int64
    filter_table::Vector{Float64}
    scale::Float64

    function Film(
        full_resolution::Pnt2i,
        cropped_pixel_bounds::Bounds2,
        filter::F,
        diagonal::Float64,
        scale::Float64,
        filename::String
    ) where F <: Filter
        filter_table_width = 16
        filter_table = zeros(Float64, filter_table_width * filter_table_width)

        # compute image bounds
        @assert cropped_pixel_bounds.pMin.x < cropped_pixel_bounds.pMax.x
        @assert cropped_pixel_bounds.pMin.y < cropped_pixel_bounds.pMax.y
        cropped_pixel_bounds = Bounds2i(
            ceil.(full_resolution .* cropped_pixel_bounds.pMin),
            ceil.(full_resolution .* cropped_pixel_bounds.pMax)
        )
        @info "Cropped Pixel Bounds at the source: $(cropped_pixel_bounds)"
        cropped_resolution = inclusive_sides(cropped_pixel_bounds)

        # allocate film image storage
        pixels = Pixel[Pixel() for _ in 1:length(cropped_pixel_bounds)]

        # precompute filter weight table
        offset = 0
        for y in 0:(filter_table_width - 1)
            for x in 0:(filter_table_width - 1)
                p = Pnt2((x + 0.5) * filter.radius.x / filter_table_width, (y + 0.5) * filter.radius.y / filter_table_width)
                filter_table[offset + 1] = filter(p)  # +1 only here for Julia indexing
                offset += 1
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
function get_sample_bounds(f::Film)::Bounds2i
    return Bounds2i(
        floor.(f.cropped_pixel_bounds.pMin .+ 0.5 .- f.filter.radius),
        ceil.(f.cropped_pixel_bounds.pMax .- 0.5 .+ f.filter.radius),
    )
end

# PBR 7.9.2
mutable struct FilmTilePixel
    contrib_sum::Spectrum
    filter_weight_sum::Float64
end

struct FilmTile
    pixel_bounds::Bounds2i
    filter_radius::Pnt2
    inv_filter_radius::Pnt2
    filter_table::Vector{Float64}
    filter_table_width::Int64
    pixels::Vector{FilmTilePixel}

    function FilmTile(f::Film, sample_bounds::Bounds2i)
        p0 = ceil.(sample_bounds.pMin .- 0.5 .- f.filter.radius)
        p1 = floor.(sample_bounds.pMax .- 0.5 .+ f.filter.radius) .+ 1
        pixel_bounds = intersection(Bounds2i(p0, p1), f.cropped_pixel_bounds)
        tile_res = inclusive_sides(pixel_bounds)
        pixels = FilmTilePixel[FilmTilePixel(spectrum_from_float(0.0, 0.0, 0.0), 0) for _ in 1:(tile_res.x * tile_res.y)]

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

function add_sample!(t::FilmTile, point::Pnt2, spectrum::S, sample_weight::Float64 = 1.0) where S <: Spectrum
    # Compute sample's raster bounds.
    discrete_point = point .- 0.5
    p0 = Pnt2i(ceil.(discrete_point .- t.filter_radius))
    p1 = Pnt2i(floor.(discrete_point .+ t.filter_radius) .+ 1)
    p0 = max.(p0, t.pixel_bounds.pMin)
    p1 = min.(p1, t.pixel_bounds.pMax)   

    # Precompute x & y filter offsets.
    offsets_x = Vector{Int64}(undef, p1.x - p0.x)
    offsets_y = Vector{Int64}(undef, p1.y - p0.y)
    for x in p0.x:(p1.x-1)
        fx = abs((x - discrete_point.x) * t.inv_filter_radius.x * t.filter_table_width)
        offsets_x[x - p0.x + 1] = min(floor(fx), t.filter_table_width - 1)  # +1 for Julia array
    end
    for y in p0.y:(p1.y-1)
        fy = abs((y - discrete_point.y) * t.inv_filter_radius.y * t.filter_table_width)
        offsets_y[y - p0.y + 1] = min(floor(fy), t.filter_table_width - 1)  # +1 for Julia array
    end
    
    # Loop over filter support & add sample to pixel array.
    width = t.pixel_bounds.pMax.x - t.pixel_bounds.pMin.x
    for y in p0.y:(p1.y-1)
        for x in p0.x:(p1.x-1)
            # Evaluate filter value at $(x,y)$ pixel
            offset_table = offsets_y[y - p0.y + 1] * t.filter_table_width + offsets_x[x - p0.x + 1]  # +1 for Julia array access
            filter_weight = t.filter_table[offset_table + 1]  # +1 for Julia array

            # Update pixel values with filtered sample contribution - DIRECT INDEXING
            # Keep offset in 0-indexed space
            offset = (x - t.pixel_bounds.pMin.x) + (y - t.pixel_bounds.pMin.y) * width
            t.pixels[offset + 1].contrib_sum += spectrum * sample_weight * filter_weight  # +1 only here
            t.pixels[offset + 1].filter_weight_sum += filter_weight  # +1 only here
        end
    end
end

function merge_film_tile!(f::Film, ft::FilmTile)
    film_width = f.cropped_pixel_bounds.pMax.x - f.cropped_pixel_bounds.pMin.x
    tile_width = ft.pixel_bounds.pMax.x - ft.pixel_bounds.pMin.x
    @info "Merging film tile $(ft.pixel_bounds)"
    
    for pixel in ft.pixel_bounds
        # Get tile pixel offset (0-indexed)
        tile_offset = (pixel.x - ft.pixel_bounds.pMin.x) + (pixel.y - ft.pixel_bounds.pMin.y) * tile_width
        
        # Get film pixel offset (0-indexed)
        film_offset = (pixel.x - f.cropped_pixel_bounds.pMin.x) + (pixel.y - f.cropped_pixel_bounds.pMin.y) * film_width
        
        # Direct mutation - +1 only at array access
        f.pixels[film_offset + 1].xyz += to_XYZ(ft.pixels[tile_offset + 1].contrib_sum)
        f.pixels[film_offset + 1].filter_weight_sum += ft.pixels[tile_offset + 1].filter_weight_sum
    end
end

function add_splat!(f::Film, p::Pnt2, v::Spectrum)
    pp = Pnt2i(trunc.(p))
    (!inside_exclusive(pp, f.cropped_pixel_bounds)) && (return)
    
    # Direct indexing for atomic operation - keep offset 0-indexed
    width = f.cropped_pixel_bounds.pMax.x - f.cropped_pixel_bounds.pMin.x
    offset = (pp.x - f.cropped_pixel_bounds.pMin.x) + (pp.y - f.cropped_pixel_bounds.pMin.y) * width
    
    Threads.atomic_add!(f.pixels[offset + 1].splat_xyz, to_XYZ(v))  # +1 only here
end

function save(film::Film, splat_scale::Float64 = 1.0)::Array{RGB}
    size = film.cropped_pixel_bounds.pMax - film.cropped_pixel_bounds.pMin

    image = Array{Float64}(undef, size.x, size.y, 3)
    
    width = film.cropped_pixel_bounds.pMax.x - film.cropped_pixel_bounds.pMin.x

    for p in film.cropped_pixel_bounds
        # Get pixel via direct indexing - keep offset 0-indexed
        offset = (p.x - film.cropped_pixel_bounds.pMin.x) + (p.y - film.cropped_pixel_bounds.pMin.y) * width
        pixel = film.pixels[offset + 1]  # +1 only here
        
        # Convert to array indices for image array
        x_idx = p.x - film.cropped_pixel_bounds.pMin.x + 1  # +1 for Julia array
        y_idx = p.y - film.cropped_pixel_bounds.pMin.y + 1  # +1 for Julia array
        
        image[x_idx, y_idx, :] .= XYZ_to_RGB(pixel.xyz)
        
        if pixel.filter_weight_sum != 0.0
            inv_weight = 1.0 / pixel.filter_weight_sum
            image[x_idx, y_idx, :] .= max.(0.0, image[x_idx, y_idx, :] .* inv_weight)
        end
        
        splat_rgb = XYZ_to_RGB(convert(XYZPBRT, pixel.splat_xyz))
        image[x_idx, y_idx, :] .+= splat_scale .* splat_rgb
        image[x_idx, y_idx, :] .*= film.scale
    end
    
    # Transpose to fix 90-degree rotation
    newimage = zeros(RGB, size.y, size.x)
    for x in 1:size.x
        for y in 1:size.y
            newimage[y, x] = RGB(image[x, y, 1], image[x, y, 2], image[x, y, 3])
        end
    end
    return newimage
end
# CHECK
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
# CHECK
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
        crop_window::Bounds2,
        filter::F,
        diagonal::Float64,
        scale::Float64,
        filename::String
    ) where F <: Filter
        filter_table_width = 16

        # compute image bounds
        @assert crop_window.pMin.x < crop_window.pMax.x
        @assert crop_window.pMin.y < crop_window.pMax.y
        cropped_pixel_bounds = Bounds2i(
            ceil.(full_resolution .* crop_window.pMin),
            ceil.(full_resolution .* crop_window.pMax)
        )

        # allocate film image storage
        pixels = Pixel[Pixel() for _ in 1:area(cropped_pixel_bounds)]

        # precompute filter weight table
        filter_table = zeros(Float64, filter_table_width * filter_table_width)
        offset = 0
        for y in 0:(filter_table_width - 1)
            for x in 0:(filter_table_width - 1)
                offset += 1
                p = Pnt2((x + 0.5) * filter.radius.x / filter_table_width, (y + 0.5) * filter.radius.y / filter_table_width)
                filter_table[offset] = filter(p)
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
# CHECK
function get_sample_bounds(f::Film)::Bounds2i
    return Bounds2i(
        floor.(f.cropped_pixel_bounds.pMin .+ 0.5 .- f.filter.radius),
        ceil.(f.cropped_pixel_bounds.pMax .- 0.5 .+ f.filter.radius),
    )
end

# CHECK
function get_pixel(f::Film, p::Pnt2i)::Pixel
    width::Int64 = f.cropped_pixel_bounds.pMax.x - f.cropped_pixel_bounds.pMin.x
    offset::Int64 = (p.x - f.cropped_pixel_bounds.pMin.x) + (p.y - f.cropped_pixel_bounds.pMin.y) * width
    return f.pixels[offset + 1]
end

# PBR 7.9.2
# CHECK
mutable struct FilmTilePixel
    contrib_sum::Spectrum
    filter_weight_sum::Float64
end

function Base.zero(::Type{FilmTilePixel})
    return FilmTilePixel(spectrum_from_float(0.0), 0.0)
end

# CHECK
struct FilmTile
    pixel_bounds::Bounds2i
    filter_radius::Pnt2
    inv_filter_radius::Pnt2
    filter_table::Vector{Float64}
    filter_table_width::Int64
    pixels::Vector{FilmTilePixel}

    function FilmTile(
        f::Film, 
        pixel_bounds::Bounds2i
    )::FilmTile
        pixels = zeros(FilmTilePixel, area(pixel_bounds))
    
        return new(
            pixel_bounds, 
            f.filter.radius, 
            1.0 ./ f.filter.radius,
            f.filter_table, 
            f.filter_table_width,
            pixels,
        )
    end 
end

# CHECK
function get_pixel(t::FilmTile, p::Pnt2i)::FilmTilePixel
    width = t.pixel_bounds.pMax.x - t.pixel_bounds.pMin.x
    offset = (p.x - t.pixel_bounds.pMin.x) + (p.y - t.pixel_bounds.pMin.y) * width
    return t.pixels[offset + 1]
end

# CHECK
function add_sample!(t::FilmTile, pfilm::Pnt2, LL::S, sample_weight::Float64 = 1.0) where S <: Spectrum
    # Compute sample's raster bounds.
    p_film_discrete = pfilm .- 0.5
    p0::Pnt2i = ceil.(p_film_discrete .- t.filter_radius)
    p1::Pnt2i = floor.(p_film_discrete .+ t.filter_radius) .+ 1
    p0 = max.(p0, t.pixel_bounds.pMin)
    p1 = min.(p1, t.pixel_bounds.pMax)   

    # Precompute x & y filter offsets.
    ifx = Vector{Int64}(undef, p1.x - p0.x)
    ify = Vector{Int64}(undef, p1.y - p0.y)
    for x in p0.x:(p1.x-1)
        fx = abs((x - p_film_discrete.x) * t.inv_filter_radius.x * t.filter_table_width)
        ifx[x - p0.x + 1] = min(floor(fx), t.filter_table_width - 1)
    end
    for y in p0.y:(p1.y-1)
        fy = abs((y - p_film_discrete.y) * t.inv_filter_radius.y * t.filter_table_width)
        ify[y - p0.y + 1] = min(floor(fy), t.filter_table_width - 1)
    end
    # Loop over filter support & add sample to pixel array.
    for y in p0.y:(p1.y-1)
        for x in p0.x:(p1.x-1)
            # Evaluate filter value at $(x,y)$ pixel
            offset = ify[y - p0.y + 1] * t.filter_table_width + ifx[x - p0.x + 1]
            filter_weight = t.filter_table[offset + 1]

            # Update pixel values with filtered sample contribution
            pixel = get_pixel(t, Pnt2i(x, y))
            pixel.contrib_sum += LL * sample_weight * filter_weight
            pixel.filter_weight_sum += filter_weight
        end
    end
end

# MOSTLY CHECK
function merge_film_tile!(f::Film, ft::FilmTile)
    for y in ft.pixel_bounds.pMin.y:(ft.pixel_bounds.pMax.y-1)
        for x in ft.pixel_bounds.pMin.x:(ft.pixel_bounds.pMax.x-1)
            pixel = Pnt2i(x, y)
            tile_pixel = get_pixel(ft, pixel)
            merge_pixel = get_pixel(f, pixel)
            @info "merge_film_tile: Spectrum - $(tile_pixel.contrib_sum), XYZ - $(to_XYZ(tile_pixel.contrib_sum))"
            merge_pixel.xyz += to_XYZ(tile_pixel.contrib_sum)
            merge_pixel.filter_weight_sum += tile_pixel.filter_weight_sum
        end
    end
end

function add_splat!(f::Film, p::Pnt2, v::Spectrum)
    pp = Pnt2i(trunc.(p))
    (!inside_exclusive(pp, f.cropped_pixel_bounds)) && (return )
    # JOHN HACK LUMINANCE CHECK
    pixel = get_pixel(f, pp)
    Threads.atomic_add!(pixel.splat_xyz, to_XYZ(v))
end

function save(film::Film, splat_scale::Float64 = 1.0)::Array{RGB}
    d::Pnt2i = film.cropped_pixel_bounds.pMax .- film.cropped_pixel_bounds.pMin
    image = Array{Float64}(undef, d.x * d.y, 3)
    offset = 0
    for y in 1:d.y
        for x in 1:d.x
            pixel = film.pixels[offset + 1]
            image[offset + 1, :] .= XYZ_to_RGB(pixel.xyz)
            # Normalize pixel with weight sum.
            filter_weight_sum = pixel.filter_weight_sum
            if filter_weight_sum != 0
                inv_weight = 1 / filter_weight_sum
                image[offset + 1, :] .= max.(0, image[offset + 1, :] .* inv_weight)
            end
            # Add splat value at pixel & scale.
            @info "save: AtomicXYZ - $(pixel.splat_xyz), XYZ - $(convert(XYZPBRT, pixel.splat_xyz)), RGB - $(XYZ_to_RGB(convert(XYZPBRT, pixel.splat_xyz)))"
            splat_rgb = XYZ_to_RGB(convert(XYZPBRT, pixel.splat_xyz))
            image[offset + 1, :] .+= splat_scale .* splat_rgb
            image[offset + 1, :] .*= film.scale
            offset += 1
        end
    end
    newimage = zeros(RGB, d.y, d.x)
    offset = 0
    for y in 1:d.y
        for x in 1:d.x
            newimage[y,x] = RGB(image[offset+1,1], image[offset+1,2], image[offset+1,3])
            offset += 1
        end
    end
    return newimage
end

# void Film::WriteImage(Float splatScale) {
#     // Convert image to RGB and compute final pixel values
#     LOG(INFO) <<
#         "Converting image to RGB and computing final weighted pixel values";
#     std::unique_ptr<Float[]> rgb(new Float[3 * croppedPixelBounds.Area()]);
#     int offset = 0;
#     for (Point2i p : croppedPixelBounds) {
#         // Convert pixel XYZ color to RGB
#         Pixel &pixel = GetPixel(p);
#         XYZToRGB(pixel.xyz, &rgb[3 * offset]);

#         // Normalize pixel with weight sum
#         Float filterWeightSum = pixel.filterWeightSum;
#         if (filterWeightSum != 0) {
#             Float invWt = (Float)1 / filterWeightSum;
#             rgb[3 * offset] = std::max((Float)0, rgb[3 * offset] * invWt);
#             rgb[3 * offset + 1] =
#                 std::max((Float)0, rgb[3 * offset + 1] * invWt);
#             rgb[3 * offset + 2] =
#                 std::max((Float)0, rgb[3 * offset + 2] * invWt);
#         }

#         // Add splat value at pixel
#         Float splatRGB[3];
#         Float splatXYZ[3] = {pixel.splatXYZ[0], pixel.splatXYZ[1],
#                              pixel.splatXYZ[2]};
#         XYZToRGB(splatXYZ, splatRGB);
#         rgb[3 * offset] += splatScale * splatRGB[0];
#         rgb[3 * offset + 1] += splatScale * splatRGB[1];
#         rgb[3 * offset + 2] += splatScale * splatRGB[2];

#         // Scale pixel value by _scale_
#         rgb[3 * offset] *= scale;
#         rgb[3 * offset + 1] *= scale;
#         rgb[3 * offset + 2] *= scale;
#         ++offset;
#     }

#     // Write RGB image
#     LOG(INFO) << "Writing image " << filename << " with bounds " <<
#         croppedPixelBounds;
#     pbrt::WriteImage(filename, &rgb[0], croppedPixelBounds, fullResolution);
# }
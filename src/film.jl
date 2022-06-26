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
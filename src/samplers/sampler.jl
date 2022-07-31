# 7.2.2
# Basic Sampler Interface
mutable struct Sampler
    samples_per_pixel::Int64
    current_pixel::Pnt2
    current_pixel_sample_index::Int64
    sample_1d_array_sizes::Vector{Int64}
    sample_2d_array_sizes::Vector{Int64}
    sample_1d_array::Vector{Vector{Float64}}
    sample_2d_array::Vector{Vector{Pnt2}}
    array_1d_offset::UInt64
    array_2d_offset::UInt64
end

# 7.2.4 Pixel Sampler
# "While some sampling algorithms can easily incrementally generate elements of each sample vector,
# others more naturally generate all of the dimensions’ sample values for all of the sample vectors for a pixel at the same time.
# The PixelSampler class implements some functionality that is useful for the implementation of these types of samplers.
mutable struct PixelSampler
    samples_per_pixel::Int64
    sampels1D::Matrix{Float64}
    sampels2D::Matrix{Pnt2}
    current1DDimension::Int64
    current2DDimension::Int64

    function PixelSampler(samples_per_pixel::Int64, n_sampled_dimensions::Int64)
        new(
            samples_per_pixel,
            zeros(Float64, n_sampled_dimensions, samples_per_pixel),
            zeros(Pnt2, n_sampled_dimensions, samples_per_pixel),
            1,
            1,
        )
    end
end

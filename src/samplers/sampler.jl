# 7.2.2
# Basic Sampler Interface
mutable struct Sampler
    samples_per_pixel::Int64
    current_pixel::Pnt2
    current_pixel_sample_index::Int64
    sample_1d_array_sizes::Vector{Int64}
    sample_2d_array_sizes::Vector{Int64}
    sample_1d_array::Matrix{Float64}
    sample_2d_array::Matrix{Pnt2}
    array_1d_offset::UInt64
    array_2d_offset::UInt64

    function Sampler(samples_per_pixel::Int64)
        return new(
            samples_per_pixel,
            Pnt2(0,0),
            1,
            zeros(Int64, 0),
            zeros(Int64, 0),
            zeros(Float64, 0, 0),
            zeros(Pnt2, 0, 0),
            1,
            1,
        )
    end
end

"""
If arrays of samples are needed, they must be requested before rendering begins.
request_{1,2}d_array() should be called for each such dimensions array before rendering begins
    - for example, in methods that override Integrator::PreProcess()
"""
function request_1d_array!(s::Sampler, n::Int64)
    push!(s.sample_1d_array_sizes, n)
    push!(s.sample_1d_array, zeros(Float64, n * s.samples_per_pixel))
end
function request_2d_array!(s::Sampler, n::Int64)
    push!(s.sample_2d_array_sizes, n)
    push!(s.sample_2d_array, zeros(Pnt2, n * s.samples_per_pixel))
end


# 7.2.4 Pixel Sampler
# "While some sampling algorithms can easily incrementally generate elements of each sample vector,
# others more naturally generate all of the dimensions’ sample values for all of the sample vectors for a pixel at the same time.
# The PixelSampler class implements some functionality that is useful for the implementation of these types of samplers.
mutable struct PixelSampler
    sampler::Sampler
    sampels1D::Matrix{Float64}
    sampels2D::Matrix{Pnt2}
    current1DDimension::Int64
    current2DDimension::Int64

    function PixelSampler(samples_per_pixel::Int64, n_sampled_dimensions::Int64)
        new(
            Sampler(samples_per_pixel),
            zeros(Float64, n_sampled_dimensions, samples_per_pixel),
            zeros(Pnt2, n_sampled_dimensions, samples_per_pixel),
            1,
            1,
        )
    end
end

# PBR 7.2.5 Global Sampler
mutable struct GlobalSampler
    sampler::Sampler
    dimension::Int64
    interval_sample_index::Int64
    array_start_dim::Int64
    array_end_dim::Int64

    function GlobalSampler(samples_per_pixel::Int64)
        return new(
            Sampler(samples_per_pixel),
            1,
            1,
            5,
            0,
        )
    end
end
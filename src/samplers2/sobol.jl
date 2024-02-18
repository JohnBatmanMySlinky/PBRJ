mutable struct SobolSampler <: AbstractSampler
    samples_per_pixel::Int64
    scale::Int64
    seed::Int64
    randomize_strategy::UInt8
    pixel::Pnt2
    dimension::Int64
    sobol_index::Int64

    function SobolSampler(
        samples_per_pixel::Int64,
        full_resolution::Pnt2,
        randomize_strategy::UInt8
    )
    return new(
        samples_per_pixel,
        round_up_pow2(max(full_resolution.x, full_resolution.y)),
        0,
        randomize_strategy,
        Pnt2(0,0),
        0,
        0
    )
    end
end

function start_pixel_sample!(ss::SobolSampler, pixel::Pnt2, sample_index::Int64, dim::Int64=0)
    # do i need this?
    @assert sample_index != ss.samples_per_pixel
    ss.pixel = pixel
    ss.dimension = max(2, dim)
    ss.sobol_index = sobol_interval_to_index(Int64(floor(log2(ss.scale))), sample_index, pixel)
end
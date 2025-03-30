mutable struct StratifiedSampler <: AbstractSampler
    samples_per_pixel::Int64
    x_samples::Int64
    y_samples::Int64
    jitter::Bool
    pixel::Pnt2
    sample_index::Int64
    dimension::Int64
    seed::Int64

    function StratifiedSampler(samples_per_pixel::Int64, jitter::Bool, seed::Int64=123456789)
        d = Int(trunc(sqrt(samples_per_pixel)))
        while samples_per_pixel % d != 0
            d -= 1
        end
        x_samples = samples_per_pixel / d
        y_samples = samples_per_pixel / x_samples
        return new(samples_per_pixel, x_samples, y_samples, jitter, Pnt2(-1,-1), 0, 0, seed)
    end
end

function start_pixel_sample!(ss::StratifiedSampler, pixel::Pnt2, sample_index::Int64, dim::Int64=0)
    # avoiding blowing my foot off here... sometimes this results in an infinite while loop in permutation_element
    @assert sample_index != ss.samples_per_pixel
    ss.pixel = pixel
    ss.sample_index = sample_index
    ss.dimension = dim
    # TODO JOHN HACK: nudge rng seed?
end

function get_1D!(ss::StratifiedSampler)::Float64
    ha = hash((ss.pixel, ss.dimension, ss.seed))
    stratum = permutation_element(UInt32(ss.sample_index), UInt32(ss.samples_per_pixel), ha)

    ss.dimension += 1
    delta = ss.jitter ? rand() : 0.5
    return (stratum + delta) / ss.samples_per_pixel
end

function get_2D!(ss::StratifiedSampler)::Pnt2
    ha = hash((ss.pixel, ss.dimension, ss.seed))
    stratum = permutation_element(UInt32(ss.sample_index), UInt32(ss.samples_per_pixel), ha)

    ss.dimension += 2
    x = stratum % ss.x_samples
    y = stratum ÷ ss.x_samples
    dx = ss.jitter ? rand() : 0.5
    dy = ss.jitter ? rand() : 0.5
    return Pnt2((x+dx)/ss.x_samples, (y+dy)/ss.y_samples)
end

function get_pixel_2D!(ss::StratifiedSampler)::Pnt2
    return get_2D!(ss)
end

function __inner_loop(i::UInt32, p::UInt32, w::UInt32)::UInt32
    i ⊻= p
    i *= 0xe170893d
    i ⊻= p >> 16
    i ⊻= (i & w) >> 4
    i ⊻= p >> 8
    i *= 0x0929eb3f
    i ⊻= p >> 23
    i ⊻= (i & w) >> 1
    i *= UInt32(1) | (p >> 27) # careful on casting here. need not worry on bit shifts
    i *= 0x6935fa69
    i ⊻= (i & w) >> 11
    i *= 0x74dcb303
    i ⊻= (i & w) >> 2
    i *= 0x9e501cc3
    i ⊻= (i & w) >> 2
    i *= 0xc860a3df
    i &= w
    i ⊻= i >> 5
    return i
end
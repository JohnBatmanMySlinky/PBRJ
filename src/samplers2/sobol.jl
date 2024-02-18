mutable struct SobolSampler <: AbstractSampler
    samples_per_pixel::Int64
    scale::Int64
    seed::Int64
    randomizer_flag::Int8
    pixel::Pnt2
    dimension::Int64
    sobol_index::Int64

    function SobolSampler(
        samples_per_pixel::Int64,
        full_resolution::Pnt2,
        randomizer_flag::Int8,
    )
    if randomizer_flag > Int8(3)
        @assert false
    end
    return new(
        samples_per_pixel,
        round_up_pow2(max(full_resolution.x, full_resolution.y)),
        0,
        randomizer_flag,
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

function get_1D!(ss::SobolSampler)::Float64
    if ss.dimension >= NSobolDimensions
        ss.dimension = 2
    end
    ss.dimension += 1
    return sample_dimension(ss)
end

function get_2D!(ss::SobolSampler)::Pnt2
    if ss.dimension + 1 >= NSobolDimensions
        ss.dimension = 2
    end
    u1 = sample_dimension(ss)
    ss.dimension += 1
    u2 = sample_dimension(ss)
    ss.dimension += 1
    u = Pnt2(u1, u2)
    return u
end

function get_pixel_2D!(ss::SobolSampler)::Pnt2
    @assert ss.dimension == 0
    u1 = sobol_sample(ss, NoRandomizer())
    ss.dimension += 1
    @assert ss.dimension == 1
    u2 = sobol_sample(ss, NoRandomizer())
    u = Pnt2(
        clamp(u1 * ss.scale - pixel.x, 0.0, 1.0-eps()),
        clamp(u2 * ss.scale - pixel.y, 0.0, 1.0-eps()),
    )
    return u
end

function sample_dimension(ss::SobolSampler)::Float64
    if ss.randomize_strategy == Int8(0) # RandomizeStrategy::None
        return sobol_sample(ss, NoRandomizer())
    end

    hash_val = hash(dimension, seed)
    if ss.randomize_strategy == Int8(1) # RandomizeStrategy::PermuteDigits
        @assert false
    elseif ss.randomize_strategy == Int8(2) # RandomizeStrategy::FastOwenScrambler
        @assert false
    else ss.randomize_strategy == Int8(3) # RandomizeStrategy::OwenScrambler
        @assert false
    end
end

function sobol_sample(ss::SobolSampler, rando::Ranomizer)::Float64
    a = ss.sobol_index
    v = UInt32(0)
    i = ss.dimension * SobolMatrixSize
    while a != 0
        if (a & 1) > 0
            v ⊻= SobolMatrices32[i+1]
        end
        a >>= 1
        i += 1
    end
    v = rando(v)
    return min(v * 0x1p-32f, 1.0-eps())
end
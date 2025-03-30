mutable struct SobolSampler <: AbstractSampler
    samples_per_pixel::Int64
    scale::Int64
    seed::Int64
    randomizer_flag::Int8
    pixel::Pnt2i
    dimension::Int64
    sobol_index::Int64

    function SobolSampler(
        samples_per_pixel::Int64,
        full_resolution::Pnt2i,
        randomizer_flag::Int8,
    )
    @assert randomizer_flag < Int8(4)
    return new(
        samples_per_pixel,
        round_up_pow2(Int64(max(full_resolution.x, full_resolution.y))),
        0,
        randomizer_flag,
        Pnt2(0,0),
        0,
        0
    )
    end
end

function start_pixel_sample!(ss::SobolSampler, pixel::Pnt2i, sample_index::Int64, dim::Int64=0)
    # do i need this?
    @assert sample_index != ss.samples_per_pixel
    ss.pixel = pixel
    # JOHN HACK: IGNORING THIS. 
    # PBRT forces dimensions to be 0 and 1 in the get_pixel_sample()
    # I just use asserts there...
    # ss.dimension = max(2, dim) 
    ss.dimension = dim
    ss.sobol_index = sobol_interval_to_index(UInt32(floor(log2(ss.scale))), UInt64(sample_index), pixel)
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
    u1 = sobol_sample(ss.sobol_index, ss.dimension, NoRandomizer())
    ss.dimension += 1
    @assert ss.dimension == 1
    u2 = sobol_sample(ss.sobol_index, ss.dimension, NoRandomizer())
    ss.dimension += 1
    u = Pnt2(
        clamp(u1 * ss.scale - ss.pixel.x, 0.0, 1.0-eps()),
        clamp(u2 * ss.scale - ss.pixel.y, 0.0, 1.0-eps()),
    )
    return u
end

function sample_dimension(ss::SobolSampler)::Float64
    if ss.randomizer_flag == Int8(0) # RandomizeStrategy::None
        return sobol_sample(ss.sobol_index, ss.dimension, NoRandomizer())
    end

    hash_val = hash((ss.dimension, ss.seed)) # JOHN HACK
    if ss.randomizer_flag == Int8(1) # RandomizeStrategy::PermuteDigits
        @assert false
    elseif ss.randomizer_flag == Int8(2) # RandomizeStrategy::FastOwenScrambler
        # John Hack truncating this to a UInt32()
        return sobol_sample(ss.sobol_index, ss.dimension, FastOwenRandomizer(UInt32(hash_val & typemax(UInt32))))
    else ss.randomizer_flag == Int8(3) # RandomizeStrategy::OwenScrambler
        @assert false
    end
end
mutable struct ZSobolSampler <: AbstractSampler
    log_2_samples_per_pixel::Int64
    samples_per_pixel::Int64
    seed::Int64
    n_base_4_digits::Int64
    randomizer_flag::Int8
    morton_index::UInt64
    dimension::Int64

    function ZSobolSampler(
        samples_per_pixel::Int64,
        full_resolution::Pnt2i,
        randomizer_flag::Int8
    )
    @assert randomizer_flag < Int8(4)
    log_2_samples_per_pixel = Int64(floor(log2(samples_per_pixel)))
    res = round_up_pow2(Int64(max(full_resolution.x, full_resolution.y)))
    log_4_samples_per_pixel = (log_2_samples_per_pixel + 1) ÷ 2
    n_base_4_digits = Int64(floor(log2(res))) + log_4_samples_per_pixel
    return new(
            log_2_samples_per_pixel,
            samples_per_pixel,
            0,
            n_base_4_digits,
            randomizer_flag,
            UInt64(0),
            0
        )
    end
end

function start_pixel_sample!(zs::ZSobolSampler, pixel::Pnt2i, sample_index::Int64, dim::Int64=0)
    # do i need this?
    @assert sample_index != zs.samples_per_pixel
    zs.dimension = dim
    
    zs.morton_index = encode_morton_2(reinterpret(UInt64, Int64(pixel.x)), reinterpret(UInt64, Int64(pixel.y))) << zs.log_2_samples_per_pixel | sample_index
end

function get_1D!(zs::ZSobolSampler)::Float64
    sample_index = get_sample_index(zs)
    zs.dimension += 1
    if zs.randomizer_flag == Int8(0)
        return sobol_sample(sample_index, 0, NoRandomizer())
    end

    hash_value = UInt32(hash((zs.dimension, zs.seed)) & typemax(UInt32))
    if zs.randomizer_flag == Int8(1)
        @assert false
    elseif zs.randomizer_flag == Int8(2)
        return sobol_sample(sample_index, 0, FastOwenRandomizer(hash_value))
    else
        @assert false
    end
end

function get_2D!(zs::ZSobolSampler)::Pnt2
    sample_index = get_sample_index(zs)
    zs.dimension += 2
    if zs.randomizer_flag == Int8(0)
        return Pnt2(
            sobol_sample(sample_index, 0, NoRandomizer()),
            sobol_sample(sample_index, 1, NoRandomizer())
        )
    end
    bits::UInt64 = hash((zs.dimension, zs.seed))
    hash_val::Tuple{UInt32, UInt32} = (UInt32(bits & typemax(UInt32)), UInt32(bits >> 32))
    if zs.randomizer_flag == Int8(1)
        @assert false
    elseif zs.randomizer_flag == Int8(2)
        return Pnt2(
            sobol_sample(sample_index, 0, FastOwenRandomizer(hash_val[1])),
            sobol_sample(sample_index, 1, FastOwenRandomizer(hash_val[2]))
        )
    else
        @assert false
    end
end

function get_pixel_2D!(zs::ZSobolSampler)::Pnt2
    return get_2D!(zs)
end

function get_sample_index(zs::ZSobolSampler)::Int64
    sample_index = 0
    pow_2_samples = (zs.log_2_samples_per_pixel & 1) > 0
    last_digit = pow_2_samples ? 1 : 0
    for i in (zs.n_base_4_digits - 1):-1:last_digit
        digit_shift = 2 * i - (pow_2_samples ? 1 : 0)
        digit = (zs.morton_index >> digit_shift) & 3
        higher_digits = zs.morton_index >> (digit_shift + 2)
        p = (mix_bits(higher_digits ⊻ (0x55555555 * zs.dimension)) >> 24) % 24
        digit = SobolPermutations[p+1][digit+1]
        sample_index |= UInt64(digit) << digit_shift
    end

    if (pow_2_samples)
        digit = zs.morton_index & 1
        sample_index |= digit ⊻ (mix_bits((zs.morton_index >> 1) ^ (0x55555555 * zs.dimension)) & 1)
    end
    return sample_index
end
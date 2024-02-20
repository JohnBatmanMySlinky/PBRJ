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
        full_resolution::Pnt2,
        randomizer_flag::Int8
    )
    @assert randomizer_flag < Int8(4)
    log_2_samples_per_pixel = Int64(floor(log2(samples_per_pixel)))
    res = round_up_pow2(max(full_resolution.x, full_resolution.y))
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

function start_pixel_sample!(zs::ZSobolSampler, pixel::Pnt2, sample_index::Int64, dim::Int64=0)
    # do i need this?
    @assert sample_index != zs.samples_per_pixel
    zs.dimension = dim
    zs.morton_index = encode_morton_2(pixel.x, pixel.y) << zs.log_2_samples_per_pixel | sample_index
end

function get_1D!(zs::SobolSampler)::Float64
    sample_index = get_sample_index(zs)
    zs.dimension += 1
    if zs.randomizer_flag == Int8(0)
        return sobol_sample(sample_index, 0, NoRandomizer())
    end

    hash_value = hash((zs.dimension, zs.seed))
    if zs.randomizer_flag == Int8(1)
        @assert false
    elseif zs.randomizer_flag == Int8(2)
        return sobol_sample(sample_index, 0, FastOwenRandomizer(hash_value))
    else
        @assert false
    end
end

function get_2D!(ss::SobolSampler)::Pnt2
    sample_index = get_sample_index(zs)
    zs.dimension += 2
end

# function get_pixel_2D!(ss::SobolSampler)::Pnt2
#     @assert ss.dimension == 0
#     u1 = sobol_sample(ss.sobol_index, ss.dimension, NoRandomizer())
#     ss.dimension += 1
#     @assert ss.dimension == 1
#     u2 = sobol_sample(ss.sobol_index, ss.dimension, NoRandomizer())
#     ss.dimension += 1
#     u = Pnt2(
#         clamp(u1 * ss.scale - ss.pixel.x, 0.0, 1.0-eps()),
#         clamp(u2 * ss.scale - ss.pixel.y, 0.0, 1.0-eps()),
#     )
#     return u
# end
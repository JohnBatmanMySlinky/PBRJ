include("primes.jl")

mutable struct HaltonSampler <: AbstractSampler
    global_sampler::GlobalSampler
    radical_inverse_permutations::Vector{UInt16}
    base_scales::Vector{Int64}
    base_exponents::Vector{Int64}
    sample_stride::Int64
    mult_inverse::Tuple{Float64, Float64}
    pixel_for_offset::Pnt2
    offset_for_current_pixel::Int64

    function HaltonSampler(samples_per_pixel::Int64, sample_bounds::Bounds2)
        global_sampler = GlobalSampler(samples_per_pixel)
        radical_inverse_permutations = compute_radical_inverse_permutations()

        # IDK JUST DEFINE THIS
        k_max_resolution = 128

        # final radical inverse base scales and exponents that cover sampling area
        base_scales = Int64[0, 0]
        base_exponents = Int64[0, 0]
        res = sample_bounds.pMax - sample_bounds.pMin
        for i = 1:2
            base = (i==0) ? 2 : 3
            scale = 1
            expo = 0
            while scale < min(res[i], k_max_resolution)
                scale *= base
                expo += 1
            end
            base_scales[i] = scale
            base_exponents[i] = expo
        end

        # compute stride in samples for visiting each pixel area
        sample_stride = base_scales[1] * base_scales[2]

        # compute multiplicative inverse for base scales
        mult_inverse = (
            multiplicative_inverse(base_scales[2], base_scales[1]),
            multiplicative_inverse(base_scales[1], base_scales[2]),
        )

        # instantiate last things
        pixel_for_offset = Pnt2(typemax(Int64), typemax(Int64))
        offset_for_current_pixel = 0
        return new(
            global_sampler,
            radical_inverse_permutations,
            base_scales,
            base_exponents,
            sample_stride,
            mult_inverse,
            pixel_for_offset,
            offset_for_current_pixel
        )
    end
end

function start_pixel!(hs::HaltonSampler, current_pixel::Pnt2)
    hs.global_sampler.dimension = 1
    hs.global_sampler.interval_sample_index = get_index_for_sample(hs, 0, current_pixel)
    array_end_dim = hs.global_sampler.array_start_dim + length(hs.global_sampler.sampler.sample_1d_array_sizes) + 2 * length(hs.global_sampler.sampler.sample_2d_array_sizes)

    for i = 1:length(hs.global_sampler.sampler.sample_1d_array_sizes)
        n_samples = 1 * hs.global_sampler.sampler.samples_per_pixel
        for j = 1:n_samples
            index = get_index_for_sample(hs, j, current_pixel)
            sample_1d_array[i][j] = sample_dimension(hs, index, array_start_dim + i)
        end
    end

    dim = hs.global_sampler.array_start_dim + length(hs.global_sampler.sampler.sample_1d_array_sizes)
    for i = 1:length(hs.global_sampler.sampler.sample_2d_array_sizes)
        n_samples = 1 * hs.global_sampler.samples_per_pixel
        for j = 1:n_samples
            idx = get_index_for_sample(hs, j, current_pixel)
            sample_2d_array[i][j] = Pnt2(
                sample_dimension(hs, idx, dim),
                sample_dimension(hs, idx, dim+1)
            )
            dim += 2
        end
    end
    @assert dim == array_end_dim
end

function get_1D!(hs::HaltonSampler)
    if hs.global_sampler.dimension >= hs.global_sampler.array_start_dim && hs.global_sampler.dimension < hs.array_end_dim
        hs.global_sampler.dimension = hs.array_end_dim
    end
    p = sample_dimension(hs, hs.global_sampler.interval_sample_index, hs.global_sampler.dimension)
    hs.global_sampler.dimension += 1
    return p
end

function get_2D!(hs::HaltonSampler)
    if hs.global_sampler.dimension + 1 >= hs.global_sampler.array_start_dim && hs.global_sampler.dimension < hs.array_end_dim
        hs.global_sampler.dimension = hs.array_end_dim
    end
    p = Pnt2(
        sample_dimension(hs, hs.global_sampler.interval_sample_index, hs.global_sampler.dimension),
        sample_dimension(hs, hs.global_sampler.interval_sample_index, hs.global_sampler.dimension+1),
    )
    hs.global_sampler.dimension += 2
    return p
end

function has_next_sample(hs::HaltonSampler)
    return hs.global_sampler.sampler.current_pixel_sample_index <= hs.global_sampler.sampler.samples_per_pixel
end
function start_next_sample!(hs::HaltonSampler)
    hs.global_sampler.dimension = 0
    hs.global_sampler.interval_sample_index = get_index_for_sample(hs, hs.global_sampler.sampler.current_pixel_sample_index, hs.global_sampler.sampler.current_pixel)
    hs.global_sampler.sampler.current_pixel_sample_index += 1
end
function get_camera_sample!(hs::HaltonSampler, ::Pnt2)
    p_film = p_raster .+ get_2D!(hs) # 1,2
    timesample = get_1D!(hs)               # 3
    p_lens = get_2D!(hs)             # 4,5
    return CameraSample(
        p_film,
        p_lens,
        timesample
    )
end

"""
The GlobalSampler helps bridge between the expectations of the Sampler interface and the natural operation of these types of samplers. 
It provides implementations of all of the pure virtual Sampler methods, 
    implementing them in terms of two new pure virtual methods that its subclasses must implement instead.
1) get_index_for_sample()
2) sample_dimension()
"""
function get_index_for_sample(hs::HaltonSampler, sample_num::Int64, current_pixel::Pnt2)::Int64
    if current_pixel != hs.pixel_for_offset
        hs.offset_for_current_pixel = 0
        if hs.sample_stride > 1
            pm = Pnt2(
                mod(current_pixel[1], k_max_resolution),
                mod(current_pixel[2], k_max_resolution),
            )
            for i = 1:2
                # JOHN dont have specialized functions?
                # dim_offset = (i==1) ? inverse_radical_inverse(pm[i], hs.base_exponents[i]) : inverse_radical_inverse(pm[i], hs.base_exponents[i])
                dim_offset = inverse_radical_inverse(pm[i], UInt(hs.base_exponents[i]))
                hs.offset_for_current_pixel += dim_offset * (hs.sample_stride / hs.base_scales[i]) * hs.mult_inverse[i]
            end
        end
        hs.pixel_for_offset = Pnt2(hs.pixel_for_offset.x % current_pixel.x, hs.pixel_for_offset.y % current_pixel.y) 
    end
    return hs.offset_for_current_pixel + sample_num * hs.sample_stride
end

function sample_dimension(hs::HaltonSampler, index::Int64, dimension::Int64)::Float64
    if dimension == 0
        return radical_inverse(dimension, UInt(index >> hs.base_exponents[1]))
    elseif dimension == 1
        return radical_inverse(dimension, UInt(index / hs.base_scales[2]))
    else
        return scrambled_radical_inverse(dimension, UInt(index), permutation_for_dimension(hs, dimension))
    end
end

##############################
### Halton Specific Functions
##############################
function inverse_radical_inverse(inverse::Int64, n_digits::Int64, base::Int64)
    index = 0
    for i = 1:n_digits
        digit = inverse % base
        inverse /= base
        index *= (base + digit)
    end
    return index
end

function radical_inverse(base_index::Int64, a::UInt64)::Float64
    @assert base_index < 1024 "Limit for radical inverse is 1023"
    (base_index == 0) && return reverse_bits(a) * 5.4210108624275222e-20

    base = PRIMES[base_index]
    inv_base = 1.0 / base
    reversed_digits = UInt64(0)
    inv_base_n = 1.0

    while a > 0
        next = UInt64(floor(a / base))
        digit = UInt64(a - next * base)
        reversed_digits = reversed_digits * base + digit
        inv_base_n *= inv_base
        a = next
    end
    return min(reversed_digits * inv_base_n, 1.0 - eps(Float64))
end

function reverse_bits(n::UInt32)::UInt32
    n = (n << 16) | (n >> 16)
    n = ((n & 0x00ff00ff) << 8) | ((n & 0xff00ff00) >> 8)
    n = ((n & 0x0f0f0f0f) << 4) | ((n & 0xf0f0f0f0) >> 4)
    n = ((n & 0x33333333) << 2) | ((n & 0xcccccccc) >> 2)
    n = ((n & 0x55555555) << 1) | ((n & 0xaaaaaaaa) >> 1)
    return n
end

function reverse_bits(n::UInt64)::UInt64
    n0 = UInt64(reverse_bits(UInt32((n << 32) >> 32)))
    n1 = UInt64(reverse_bits(UInt32(n >> 32)))
    return (n0 << 32) | n1
end

"""
The ComputeRadicalInversePermutations() function computes these random permutation tables. 
It initializes a single contiguous array for all of the permutations, 
        where the first two values are a permutation of the integers 0 and 1 for b=2, 
        the next three values are a permutation of 0,1,2 for b=3, 
        and so forth for successive prime bases. 
At entry to the for loop below, p points to the start of the permutation array to initialize for the current prime base.
"""
# JOHN: idk how tf that c++ code does the above, so hacking away!
function compute_radical_inverse_permutations()::Vector{UInt16}
    # allocate space in perms for radical inverse permutations
    perm_array_size = sum(PRIMES)
    perms = Vector{UInt16}(undef, perm_array_size)

    running = 0
    for i = 1:length(PRIMES)
    # generate random permutation for the ith prime base
    # JOHN HACK
        tmp_array = collect(1:PRIMES[i])
        shuffle!(tmp_array, PRIMES[i], 1)
        for j = 1:length(tmp_array)
            running += 1
            perms[running] = convert(UInt16, tmp_array[j])
        end
    end
    return perms
end

function permutation_for_dimension(hs::HaltonSampler, dimension::Int64)
    @assert dimension <= length(hs.radical_inverse_permutations)
    return hs.radical_inverse_permutations[PRIME_SUM[dimension]]
end

# JOHN HACK
function scrambled_radical_inverse(base_index::Int64, a::UInt64, perm::Any)::Float64
    @assert base_index < 1024 "Limit for radical inverse is 1023"
    (base_index == 0) && return reverse_bits(a) * 5.4210108624275222e-20

    base = PRIMES[base_index]
    inv_base = 1.0 / base
    reversed_digits = UInt64(0)
    inv_base_n = 1.0

    while a > 0
        next = UInt64(floor(a / base))
        digit = UInt64(a - next * base)
        reversed_digits = reversed_digits * base + perm[digit]
        inv_base_n *= inv_base
        a = next
    end
    return min(inv_base_n * (reversed_digits = inv_base * perm[1] / (1-inv_base)), 1.0 - eps(Float64))
end
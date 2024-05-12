function sobol_sample(a::Int64, dimension::Int64, rando::Randomizer)::Float64
    v = UInt32(0)
    i = dimension * SobolMatrixSize
    while a != 0
        if (a & 1) > 0
            v ⊻= SobolMatrices32[i+1]
        end
        a >>= 1
        i += 1
    end
    v = rando(v)
    return min(v * 0x1p-32, 1.0-eps())
end

function radical_inverse(prime_index::Int64, a::UInt64)::Float64
    # JOHN HACK: to keep prime index matching, hiding the offset in here
    base = PRIMES[prime_index+1]
    # C++ trickery: ~0ull translates to
    # bitwise NOT of a '0' that is 'u'nsigned and 'l'ong 'l'ong aka a typemax!
    limit::UInt64 = typemax(UInt64) / base - base
    inv_base::Float64 = 1.0 / base
    inv_base_M::Float64 = 1.0
    reversed_digits::UInt64 = UInt64(0)
    while ((a >= 1) && (reversed_digits < limit))
        next::UInt64 = a ÷ base
        digit::UInt64 = a - next * base
        reversed_digits = reversed_digits * base + digit
        inv_base_M *= inv_base
        a = next
    end
    return min(reversed_digits * inv_base_M, 1.0-eps());
end

function sobol_interval_to_index(m::UInt32, frame::UInt64, p::Pnt2)::Int64
    if m == 0
        return frame
    end

    m2::UInt32 = m << 1
    index::UInt64 = frame << m2

    delta::UInt64 = 0
    c = 0
    while frame > 0 # ChatGPT told me it iterates while frame is non-zero
        if (frame & 1) > 0
            delta ⊻= VdCSobolMatrices[m-1+1][c+1]
        end
        frame >>= 1 # remember kids, incrementing happens last
        c += 1
    end

    # flipped b
    # JOHN HACK: some sillyness with the truncation here? how big could pixel be?
    b = UInt64((UInt32(Int64(p.x) & typemax(UInt32))) << m) | UInt32(Int64(p.y) & typemax(UInt32)) ⊻ delta
    c = 0
    while b > 0
        if (b & 1) > 0
            index ⊻= VdCSobolMatricesInv[m-1+1][c+1]
        end
        b >>= 1 # remember kids, incrementing happens last
        c += 1 
    end
    return index
end

function permutation_element(i::UInt32, l::UInt32, p::Union{UInt, Int})::Int64
    # JOHN HACK: this will break if l or i > typemax(UInt32)
    p = UInt32(p & typemax(UInt32)) # PBRT's hash is a uint64_t and PermutationElement does the truncation. we have to do it explicitly.
    w = l - UInt32(1) # careful on casting
    w |= w >> 1
    w |= w >> 2
    w |= w >> 4
    w |= w >> 8
    w |= w >> 16
    i = __inner_loop(i, p, w) # We don't have a do-while only while-do
    while i >= l
        i = __inner_loop(i, p, w)
    end
    return (i + p) % l
end

function mix_bits(v::Union{Int, UInt})::Union{Int, UInt}
    v ⊻= (v >> 31)
    v *= 0x7fb5d329728ea185
    v ⊻= (v >> 27)
    v *= 0x81dadef4bc2dd44d
    v ⊻= (v >> 33)
    return v
end

function reverse_bits_32(n::UInt32)::UInt32
    n = (n << 16) | (n >> 16)
    n = ((n & 0x00ff00ff) << 8) | ((n & 0xff00ff00) >> 8)
    n = ((n & 0x0f0f0f0f) << 4) | ((n & 0xf0f0f0f0) >> 4)
    n = ((n & 0x33333333) << 2) | ((n & 0xcccccccc) >> 2)
    n = ((n & 0x55555555) << 1) | ((n & 0xaaaaaaaa) >> 1)
    return n;
end
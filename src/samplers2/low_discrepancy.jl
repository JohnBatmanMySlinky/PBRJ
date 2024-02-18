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
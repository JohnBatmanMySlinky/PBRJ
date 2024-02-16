const Primes::Vector{Int64} = Int64[2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59]

function radical_inverse(prime_index::Int64, a::UInt64)::Float64
    base = Primes[prime_index]
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

print(radical_inverse(1, UInt64(3)))
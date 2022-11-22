include("primes.jl")


function radical_inverse(base_index::Int64, a::UInt64)::Float64
    @assert base_index < 1024 "Limit for radical inverse is 1023"
    (base_index == 0) && return reverse_bits(a) * 5.4210108624275222e-20

    base = PRIMES[base_index]
    inv_base = 1.0 / base
    reveresed_bits = UInt64(0)
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
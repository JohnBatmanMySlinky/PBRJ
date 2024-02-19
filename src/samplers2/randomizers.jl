struct NoRandomizer <: Randomizer
end

function (r::NoRandomizer)(a::UInt32)::UInt32
    return a
end

struct FastOwenRandomizer <: Randomizer
    seed::UInt32
    function FastOwenRandomizer()
        return new(UInt32(15689))
    end
end

function (r::FastOwenRandomizer)(v::UInt32)::UInt32
    v = reverse_bits_32(v)
    v ⊻= v * 0x3d20adea
    v += r.seed
    v *= (r.seed >> 16) | 1
    v ⊻= v * 0x05526c56
    v ⊻= v * 0x53a22864
    return reverse_bits_32(v)
end

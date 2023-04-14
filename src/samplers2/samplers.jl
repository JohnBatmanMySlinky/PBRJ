function inner_loop(i::UInt32, p::UInt32, w::UInt32)::UInt32
    i ⊻= p
    i *= 0xe170893d
    i ⊻= p >> 16
    i ⊻= (i & w) >> 4
    i ⊻= p >> 8
    i *= 0x0929eb3f
    i ⊻= p >> 23
    i ⊻= (i & w) >> 1
    i *= UInt32(1) | (p >> 27)
    i *= 0x6935fa69
    i ⊻= (i & w) >> 11
    i *= 0x74dcb303
    i ⊻= (i & w) >> 2
    i *= 0x9e501cc3
    i ⊻= (i & w) >> 2
    i *= 0xc860a3df
    i &= w
    i ⊻= i >> 5
    return i
end

function PermutationElement(i::UInt32, l::UInt32, p::Int)::Int32
    p = UInt32(p & typemax(UInt32))
    print("HASH: $(p)\n")
    w = l - UInt32(1)
    w |= w >> 1
    w |= w >> 2
    w |= w >> 4
    w |= w >> 8
    w |= w >> 16
    i = inner_loop(i, p, w) # JOHN HACK: we don't have a do while only while do
    while i >= l
        i = inner_loop(i, p, w)
    end
    return (i + p) % l
end
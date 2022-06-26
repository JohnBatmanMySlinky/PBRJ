# 8.1 Basic Interface

const BSDF_NONE         = UInt8(0b00000)
const BSDF_REFLECTION   = UInt8(0b00001)
const BSDF_TRANSMISSION = UInt8(0b00010)
const BSDF_DIFFUSE      = UInt8(0b00100)
const BSDF_GLOSSY       = UInt8(0b01000)
const BSDF_SPECULAR     = UInt8(0b10000)
const BSDF_ALL          = UInt8(0b11111)

function Base.:&(b::B, type::UInt8)::Bool where B <: AbstractBxDF
    (b.type & type) == b.type
end



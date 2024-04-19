struct ConstantTexture <: Texture
    value::Spectrum
end

function (c::ConstantTexture)(si::SurfaceInteraction)
    @assert false
    return c.value
end

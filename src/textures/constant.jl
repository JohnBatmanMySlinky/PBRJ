struct ConstantTexture <: Texture
    value::Spectrum
end

function (c::ConstantTexture)(si::SurfaceInteraction)
    return c.value
end

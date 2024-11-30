struct ConstantTexture <: Texture
    value::Spectrum
end

function (c::ConstantTexture)(si::SurfaceInteraction)
    return c.value
end

struct ConstantTextureFloat <: Texture
    value::Float64
end

function (c::ConstantTextureFloat)(si::SurfaceInteraction)
    return c.value
end

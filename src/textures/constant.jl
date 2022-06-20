struct ConstantTexture <: Texture
    value::Vec3
end

function (c::ConstantTexture)(si::SurfaceInteraction)
    return c.value
end

struct ConstantTexture <: Texture
    value::Pnt3
end

function (c::ConstantTexture)(si::SurfaceInteraction)
    return c.value
end

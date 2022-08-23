struct ConstantTexture <: Texture
    value::Pnt3
end

function (c::ConstantTexture)(si::SurfaceInteraction)
    return c.value
end

# JOHN's to make for fsater bump mapping?
function (c::ConstantTexture)(uv::Pnt2)
    return c.value
end

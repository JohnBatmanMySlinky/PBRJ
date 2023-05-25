struct ConstantTexture <: Texture
    color::Vec3
end

function color_value(ct::ConstantTexture, u::Float64, v::Float64, p::Vec3)::Vec3
    return ct.color
end
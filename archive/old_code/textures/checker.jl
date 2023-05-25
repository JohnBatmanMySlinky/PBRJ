struct CheckerTexture <: Texture
    color1::Vec3
    color2::Vec3
    x::Float64
    y::Float64
    z::Float64
end

function color_value(ct::CheckerTexture, u::Float64, v::Float64, p::Vec3)::Vec3
    sines = sin(ct.x * p[1]) * sin(ct.y * p[2]) * sin(ct.z * p[3])
    if sines < 0 
        return ct.color1
    else
        return ct.color2
    end
end
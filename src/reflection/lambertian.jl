struct LambertianReflection <: BxDF
    r::Vec3
    type::UInt8

    function LambertianReflection(r::Vec3)
        new(r, BSDF_DIFFUSE | BSDF_REFLECTION)
    end
end

function (l::LambertianReflection)(::Vec3, ::Vec3)::Vec3
    return l.r / pi
end
function rho(l::LambertianReflection, ::Vec3, ::Vec3, ::Int64, ::Vector{Vec2})
    l.r
return 
function rho(l::LambertianReflection, ::Vector{Vec2}, ::Vector{Vec2})
    l.r
return 



struct LambertianTransmission <: BxDF
    t::Vec3
    type::UInt8

    function LambertianTransmission(t::Vec3)
        new(t, BSDF_DIFFUSE | BSDF_TRANSMISSION)
    end
end

function (t::LambertianTransmission)(::Vec3f0, ::Vec3f0)::Vec3
    return t.t / pi
end

function rho(t::LambertianTransmission, ::Vec3f0, ::Int32, ::Vector{Vec2})
    return t.t
end

function rho(t::LambertianTransmission, ::Vector{Point2f0}, ::Vector{Point2f0})
    return t.t
end
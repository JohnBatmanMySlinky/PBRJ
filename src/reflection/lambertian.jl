# PBR 8.3 LambertianReflection
struct LambertianReflection <: AbstractBxDF
    r::Spectrum
    type::UInt8

    function LambertianReflection(r::Spectrum)
        new(r, BSDF_DIFFUSE | BSDF_REFLECTION)
    end
end

function f(l::LambertianReflection, ::Vec3, ::Vec3)::Spectrum
    return l.r / pi
end

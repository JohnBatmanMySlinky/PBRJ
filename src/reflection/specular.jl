# 8.2.2 Specular Reflection
struct SpecularReflection{F} <: AbstractBxDF
    r::Spectrum
    fresnel::F
    type::UInt8
    function SpecularReflection(r::Spectrum, fresnel::F) where {F}
        new{F}(r, fresnel, BSDF_SPECULAR | BSDF_REFLECTION)
    end
end

function f(s::SpecularReflection, ::Vec3, ::Vec3)::Spectrum
    return spectrum_from_float(0.0, 0.0, 0.0)
end

function sample_f(s::SpecularReflection, wo::Vec3, u::Pnt2, type::UInt8=BSDF_ALL)::Tuple{Vec3, Spectrum, Float64, Maybe{UInt8}}
    wi = Vec3(-wo.x, -wo.y, wo.z)
    return wi, s.fresnel(cos_theta(wi)) * s.r / abs_cos_theta(wi), 1.0, nothing
end

function compute_pdf(f::SpecularReflection, wo::Vec3, wi::Vec3)::Float64
    return 0.0
end

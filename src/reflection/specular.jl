# 8.2.2 Specular Reflection
struct SpecularReflection{S <: Spectrum, F<:Fresnel} <: AbstractBxDF
    r::S
    fresnel::F
    type::UInt8
    function SpecularReflection(r::S, fresnel::F) where {S <: Spectrum, F <: Fresnel}
        new{S, F}(r, fresnel, BSDF_SPECULAR | BSDF_REFLECTION)
    end
end

# equivalent to PBR's f()
# "No scattering is returned from f(), since for an arbitrary pair of directions the delta function returns no scattering."
function f(s::SpecularReflection{S, F}, ::Vec3, ::Vec3)::Spectrum where {S <: Spectrum, F <: Fresnel}
    return spectrum_from_float(0.0, 0.0, 0.0)
end

function sample_f(s::SpecularReflection{S, F}, wo::Vec3, u::Pnt2, type::UInt8=BSDF_ALL)::Tuple{Vec3, Spectrum, Float64, Maybe{UInt8}} where {S <: Spectrum, F <: Fresnel}
    wi = Vec3(-wo.x, -wo.y, wo.z)
    return wi, s.fresnel(cos_theta(wi)) * s.r / abs_cos_theta(wi), 1.0, nothing
end

function compute_pdf(f::SpecularReflection{S, F}, wo::Vec3, wi::Vec3)::Float64 where {S <: Spectrum, F <: Fresnel}
    return 0.0 
end
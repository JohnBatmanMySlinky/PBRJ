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
function (s::SpecularReflection{S, F})(::Vec3f0, ::Vec3f0)::Spectrum where {S <: Spectrum, F <: Fresnel}
    return Spectrum(0, 0, 0)
end

function sample_f(s::SpecularReflection{S, F}, wo::Vec3, wi::Vec3, sample::Pnt2)::Tuple{Vec3, Float64, Spectrum, Maybe{UInt8}} where {S <: Spectrum, F <: Fresnel}
    wi = Vec3(-wi.x, -wi.y, wz)
    return wi, 1.0, s.fresnel(cos_theta(wi)) * s.r / abs_cos_theta(wi), nothing
end

# 8.2.3 Specular Transmission
# TODO


# 8.2.4 Fresnel Specular
# TODO
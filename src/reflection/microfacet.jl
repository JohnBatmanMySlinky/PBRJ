# PBR 8.4.4 The Torrance-Sparrow  Model
struct MicrofacetReflection <: AbstractBxDF
    R::Spectrum
    distrib::MicrofacetDistribution
    fresnel::Fresnel
    type::UInt8
    function MicrofacetReflection(R::Spectrum, distrib::MicrofacetDistribution, fresnel::Fresnel)
        return new(
            R, distrib, fresnel, BSDF_REFLECTION | BSDF_GLOSSY    
        )
    end
end

function f(mr::MicrofacetReflection, wo::Vec3, wi::Vec3)
    cos_theta_o = abs(cos_theta(wo))
    cos_theta_i = abs(cos_theta(wi))
    wh = wo + wi
    if cos_theta_i == 0 || cos_theta_o == 0
        return Spectrum(0)
    end
    if wh.x == 0 && wh.y == 0 & wh.z == 0
        return Spectrum(0)
    end
    wh = normalize(wh)
    F = mr.fresnel(dot(wi, face_forward(wh, Vec3(0,0,1))))
    return mr.R * D(mr.distrib, wh) * G(mr.distrib, wo, wi) * F / (4.0 * cos_theta_i * cos_theta_o)
end
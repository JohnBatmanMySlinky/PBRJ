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

function f(mr::MicrofacetReflection, wo::Vec3, wi::Vec3)::Spectrum
    cos_theta_o = abs(cos_theta(wo))
    cos_theta_i = abs(cos_theta(wi))
    wh = wo + wi
    if cos_theta_i == 0 || cos_theta_o == 0
        return spectrum_from_float(0.0)
    end
    if wh.x == 0 && wh.y == 0 && wh.z == 0
        return spectrum_from_float(0.0)
    end
    wh = normalize(wh)
    F = mr.fresnel(dot(wi, face_forward(wh, Vec3(0,0,1))))
    # @info "F: $F"
    # @info "D: $(D(mr.distrib, wh))"
    # @info "G: $(G(mr.distrib, wo, wi))"
    return mr.R * D(mr.distrib, wh) * G(mr.distrib, wo, wi) * F / (4.0 * cos_theta_i * cos_theta_o)
end

function sample_f(bxdf::MicrofacetReflection, wo::Vec3, u::Pnt2, type::UInt8=BSDF_ALL)::Tuple{Vec3, Spectrum, Float64, Maybe{UInt8}}
    # @info "METALDEBUG: sample_f: wo: $wo"

    # Sample microfacet orientation $\wh$ and reflected direction $\wi$
    if (wo.z == 0) 
        return Vec3(0, 0, 0), spectrum_from_float(0.0), 0.0, nothing
    end
    wh = sample_wh(bxdf.distrib, wo, u)
    # @info "METALDEBUG: sample_f: wh: $wh"
    if (dot(wo, wh) < 0) 
        return Vec3(0, 0, 0), spectrum_from_float(0.0), 0.0, nothing   # Should be rare
    end
    wi = reflect(wo, wh)
    # @info "METALDEBUG: sample_f: wi: $wi"
    if (!same_hemisphere(wo, wi)) 
        return Vec3(0, 0, 0), spectrum_from_float(0.0), 0.0, nothing
    end

    # Compute PDF of _wi_ for microfacet reflection
    pdf_val = compute_pdf(bxdf.distrib, wo, wh) / (4.0 * dot(wo, wh))
    # @info "METALDEBUG: sample_f: pdf_val: $pdf_val"
    f_val = f(bxdf, wo, wi)
    return wi, f_val, pdf_val, nothing
end

function compute_pdf(bxdf::MicrofacetReflection, wo::Vec3, wi::Vec3)::Float64
    if (!same_hemisphere(wo, wi)) 
        return 0.0
    end
    wh = normalize(wo + wi);
    return compute_pdf(bxdf.distrib, wo, wh) / (4.0 * dot(wo, wh))
end


struct MicrofacetTransmission <: AbstractBxDF
    T::Spectrum
    distribution::MicrofacetDistribution
    eta_A::Float64
    eta_B::Float64
    fresnel::FresnelDielectric
    mode::Type{T} where T <: TransportMode
    type::UInt8
    function MicrofacetTransmission(T::Spectrum, distribution::MicrofacetDistribution, eta_A::Float64, eta_B::Float64, mode)
        return new(
            T, distribution, eta_A, eta_B, FresnelDielectric(eta_A, eta_B), mode, BSDF_TRANSMISSION | BSDF_GLOSSY
        )
    end
end

function f(mt::MicrofacetTransmission, wo::Vec3, wi::Vec3)::Spectrum
    if same_hemisphere(wo, wi)
        return spectrum_from_float(0.0)
    end
    
    cos_theta_O = cos_theta(wo)
    cos_theta_I = cos_theta(wi)
    if (cos_theta_O == 0.0) || (cos_theta_I == 0.0)
        return spectrum_from_float(0.0)
    end

    # Compute $\wh$ from $\wo$ and $\wi$ for microfacet transmission
    eta = cos_theta_O > 0 ? (mt.eta_B / mt.eta_A) : (mt.eta_A / mt.eta_B)
    wh = normalize(wo + wi * eta)
    if (wh.z < 0) 
        wh = -wh
    end
    
    # Same side?
    if (dot(wo, wh) * dot(wi, wh) > 0.0)
        return spectrum_from_float(0.0)
    end
    
    F = mt.fresnel(dot(wo, wh))
    sqrtDenom = dot(wo, wh) + eta * dot(wi, wh)
    factor = (mt.mode == Radiance) ? (1 / eta) : 1.0
    @info "little f: $F, $sqrtDenom, $factor, $(D(mt.distribution, wh)), $(G(mt.distribution, wo, wi))"
    
    return (spectrum_from_float(1.0) .- F) * mt.T *
            abs(D(mt.distribution, wh) * G(mt.distribution, wo, wi) * eta * eta *
                    abs(dot(wi, wh)) * abs(dot(wo, wh)) * factor * factor /
                    (cos_theta_I * cos_theta_O * sqrtDenom * sqrtDenom))
end

function sample_f(bxdf::MicrofacetTransmission, wo::Vec3, u::Pnt2, type::UInt8=BSDF_ALL)::Tuple{Vec3, Spectrum, Float64, Maybe{UInt8}}
    if (wo.z == 0) 
        return Vec3(0, 0, 0), spectrum_from_float(0.0), 0.0, nothing
    end
    wh = sample_wh(bxdf.distribution, wo, u)
    @info "BxDF::sample_f: wh: $wh"
    if (dot(wo, wh) < 0) 
        # Should be rare
        return Vec3(0, 0, 0), spectrum_from_float(0.0), 0.0, nothing
    end

    eta = cos_theta(wo) > 0 ? (bxdf.eta_A / bxdf.eta_B) : (bxdf.eta_B / bxdf.eta_A)
    wi = refract(wo, Nml3(wh), eta)
    @info "BxDF::sample_f: wi $wi"
    if (wi isa Nothing) 
        return Vec3(0, 0, 0), spectrum_from_float(0.0), 0.0, nothing
    end
    pdf_val = compute_pdf(bxdf, wo, wi)
    @info "BxDF::pdf_val: wi $pdf_val"
    return wi, f(bxdf, wo, wi), pdf_val, nothing
end

function compute_pdf(bxdf::MicrofacetTransmission, wo::Vec3, wi::Vec3)::Float64
    if same_hemisphere(wo, wi)
        return 0.0
    end
    # Compute $\wh$ from $\wo$ and $\wi$ for microfacet transmission
    eta = cos_theta(wo) > 0 ? (bxdf.eta_B / bxdf.eta_A) : (bxdf.eta_A / bxdf.eta_B)
    wh = normalize(wo + wi * eta)

    if (dot(wo, wh) * dot(wi, wh) > 0) 
        return 0.0
    end

    # Compute change of variables _dwh\_dwi_ for microfacet transmission
    sqrtDenom = dot(wo, wh) + eta * dot(wi, wh)
    dwh_dwi = abs((eta * eta * dot(wi, wh)) / (sqrtDenom * sqrtDenom))
    @info "compute_pdf: $dwh_dwi, $sqrtDenom, $wo, $wi"
    @info "computer_pdf: $(compute_pdf(bxdf.distribution, wo, wh))"
    return compute_pdf(bxdf.distribution, wo, wh) * dwh_dwi
end
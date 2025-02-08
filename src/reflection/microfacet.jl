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
    if wh.x == 0 && wh.y == 0 & wh.z == 0
        return spectrum_from_float(0.0)
    end
    wh = normalize(wh)
    F = mr.fresnel(dot(wi, face_forward(wh, Vec3(0,0,1))))
    @info "F: $F"
    @info "D: $(D(mr.distrib, wh))"
    @info "G: $(G(mr.distrib, wo, wi))"
    return mr.R * D(mr.distrib, wh) * G(mr.distrib, wo, wi) * F / (4.0 * cos_theta_i * cos_theta_o)
end

function sample_f(bxdf::MicrofacetReflection, wo::Vec3, u::Pnt2, type::UInt8=BSDF_ALL)::Tuple{Vec3, Spectrum, Float64, Maybe{UInt8}}
    @info "METALDEBUG: sample_f: wo: $wo"

    # Sample microfacet orientation $\wh$ and reflected direction $\wi$
    if (wo.z == 0) 
        return Vec3(0, 0, 0), spectrum_from_float(0.0), 0.0, nothing
    end
    wh = sample_wh(bxdf.distrib, wo, u)
    @info "METALDEBUG: sample_f: wh: $wh"
    if (dot(wo, wh) < 0) 
        return Vec3(0, 0, 0), spectrum_from_float(0.0), 0.0, nothing   # Should be rare
    end
    wi = reflect(wo, wh)
    @info "METALDEBUG: sample_f: wi: $wi"
    if (!same_hemisphere(wo, wi)) 
        return Vec3(0, 0, 0), spectrum_from_float(0.0), 0.0, nothing
    end

    # Compute PDF of _wi_ for microfacet reflection
    pdf_val = compute_pdf(bxdf.distrib, wo, wh) / (4.0 * dot(wo, wh))
    @info "METALDEBUG: sample_f: pdf_val: $pdf_val"
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

# PBR 8.2.1 Fresnel Reflectance

############################################################
###################### Fresnel Conductors ##################
############################################################

struct FresnelConductor{S <: Spectrum} <: Fresnel
    eta_i::S
    eta_t::S
    k::S
end

function(f::FresnelConductor)(cos_theta_i::Float64) 
    return fresnel_conductor(cos_theta_i, f.eta_i, f.eta_t, f.k)
end

function fresnel_conductor(cos_theta_i::Float64, eta_i::Spectrum, eta_t::Spectrum, k::Spectrum)::Spectrum
    cos_theta_i = clamp(cos_theta_i, -1, 1)
    eta::Spectrum = eta_t ./ eta_i
    eta_k::Spectrum = k ./ eta_i

    cos_theta_i_2::Float64 = cos_theta_i ^ 2 
    sin_theta_i_2::Float64 = 1.0 - cos_theta_i_2
    eta_2::Spectrum = eta .^ 2
    eta_k_2::Spectrum = eta_k .^ 2

    t0::Spectrum = eta_2 .- eta_k_2 .- sin_theta_i_2
    a2_plus_b2::Spectrum = sqrt.(t0 .^ 2 .+ 4.0 .* eta_2 .* eta_k_2)
    t1::Spectrum = a2_plus_b2 .+ cos_theta_i_2
    a::Spectrum = sqrt.(0.5 .* (a2_plus_b2 .+ t0))
    t2::Spectrum = 2.0 .* cos_theta_i .* a
    r_perp::Spectrum = (t1 .- t2) ./ (t1 .+ t2)

    t3::Spectrum = cos_theta_i_2 .* a2_plus_b2 .+ sin_theta_i_2 .* sin_theta_i_2
    t4::Spectrum = t2 .* sin_theta_i_2
    r_par::Spectrum = r_perp .* (t3 .- t4) ./ (t3 .- t4)
    return (r_par .+ r_perp) ./ 2.0
end

############################################################
###################### Fresnel Dielectrics #################
############################################################

struct FresnelDielectric <: Fresnel
    eta_i::Float64
    eta_t::Float64
end

function(f::FresnelDielectric)(cos_theta_i)
    return fresnel_dielectric(cos_theta_i, f.eta_i, f.eta_t)
end

function fresnel_dielectric(cos_theta_i::Float64, eta_i::Float64, eta_t::Float64)
    cos_theta_i = clamp(cos_theta_i, -1, 1)
    if cos_theta_i <= 0
        eta_i, eta_t = eta_t, eta_i
        cos_theta_i = abs(cos_theta_i)
    end

    sin_theta_i = sqrt(max(0, 1-cos_theta_i^2))
    sin_theta_t = sin_theta_i * eta_i / eta_t
    if sin_theta_t >= 1
        return 1
    end
    cos_theta_t = sqrt(max(0, 1-sin_theta_t^2))

    r_par = (eta_t * cos_theta_i - eta_i * cos_theta_t) / (eta_t * cos_theta_i + eta_i * cos_theta_t)
    r_perp = (eta_i * cos_theta_i - eta_t * cos_theta_t) / (eta_i * cos_theta_i + eta_t * cos_theta_t)

    return (r_par + r_perp) / 2
end


############################################################
###################### Fresnel No Op #################
############################################################

struct FresnelNoOp <: Fresnel
end

function (f::FresnelNoOp)(::Float64)
    return spectrum_from_float(1,1,1)
end


############################################################
###################### Fresnel Blend #######################
############################################################
struct FresnelBlend <: AbstractBxDF
    Rd::Spectrum
    Rs::Spectrum
    distrib::MicrofacetDistribution
    type::UInt8
    function FresnelBlend(Rd::Spectrum, Rs::Spectrum, distrib::MicrofacetDistribution)
        return new(
            Rd, Rs, distrib, BSDF_REFLECTION | BSDF_GLOSSY    
        )
    end
end

function SchlickFresnel(Rs::Spectrum, cos_theta::Float64)
    return Rs + (spectrum_from_float(1.0, 1.0, 1.0)-Rs)*(1-cos_theta)^5
end

function f(f::FresnelBlend, wo::Vec3, wi::Vec3)
    diffuse = (28 / (23pi)) * f.Rd * (spectrum_from_float(1.0)-f.Rs) * (1-(1-abs_cos_theta(wi)/2)^5) * (1-(1-abs_cos_theta(wo)/2)^5)
    wh = wi + wo
    (wh.x==0)&&(wh.y==0)&&(wh.z==0) && return spectrum_from_float(0.0)
    wh = normalize(wh)
    specular = spectrum_from_float(D(f.distrib, wh) / (4 * abs(dot(wi,wh)) * max(abs_cos_theta(wo), abs_cos_theta(wi))) * SchlickFresnel(f.Rs, dot(wi, wh)))
    return diffuse + specular
end

############################################################
###################### Fresnel Specular ####################
############################################################
struct FresnelSpecular <: AbstractBxDF
    R::Spectrum
    TT::Spectrum
    etaA::Float64
    etaB::Float64
    fresnel::FresnelDielectric
    mode::Type{T} where T <: TransportMode
    type::UInt8
    function FresnelSpecular(R::Spectrum, TT::Spectrum, etaA::Float64, etaB::Float64, mode::Type{T}) where T <: TransportMode
        return new(R, TT, etaA, etaB, FresnelDielectric(etaA, etaB), mode, BSDF_REFLECTION | BSDF_TRANSMISSION | BSDF_SPECULAR)
    end
end

function f(s::FresnelSpecular, wo::Vec3, wi::Vec3)::Spectrum
    return spectrum_from_float(0.0)
end

function sample_f(s::FresnelSpecular, wo::Vec3, u::Pnt2, type::UInt8)::Tuple{Vec3, Spectrum, Float64, Maybe{UInt8}}
    F = fresnel_dielectric(cos_theta(wo), s.etaA, s.etaB)
    if u.x < F
        # compute specular reflection direction
        wi = Vec3(-wo.x, -wo.y, wo.z)
        sampled_type = BSDF_SPECULAR | BSDF_REFLECTION
        pdf_val = F
        return wi, F * s.R / abs(cos_theta(wi)), pdf_val, sampled_type
    else
        # compute specular transmission for fresnel specular

        # figure otu which eta is incident and which is transmitted
        entering = cos_theta(wo) > 0
        etaI = entering ? s.etaA : s.etaB
        etaT = entering ? s.etaB : s.etaA

        # compute ray direction for specular transmission
        check, wi = refact(wo, face_forward(Nml3(0,0,1), wo), etaI / etaT)
        if !check
            return Vec3(0.0), spectrum_from_float(0.0), 0.0, nothing
        end
        ft = s.TT * (1-F)

        # account for non-symmetry for specular transmission to different medium
        if s.mode == Radiance
            ft *= (etaI * etaI) / (etaT * etaT)
        end
        sampled_type = BSDF_SPECULAR | BSDF_TRANSMISSION
        pdf_val = 1-F
        return wi, ft / abs(cos_theta(wi)), pdf_val, sampled_type
    end
end

function refact(wi::Vec3, n::Nml3, eta::Float64)::Tuple{Bool, Vec3}
    # comute cos theta t using snells law
    cos_theta_I = dot(n,wi)
    sin_2_theta_I = max(0.0, 1-cos_theta_I^2)
    sin_2_theta_T = eta * eta * sin_2_theta_I

    # handle total internal reflection for transmission
    if sin_2_theta_T >= 1
        return false, Vec3(0)
    end
    cos_theta_T = sqrt(1-sin_2_theta_T)
    wt = eta * -wi + (eta * cos_theta_I - cos_theta_T) * Vec3(n)
    return true, wt
end
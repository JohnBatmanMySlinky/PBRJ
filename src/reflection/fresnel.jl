# PBR 8.2.1 Fresnel Reflectance

############################################################
###################### Fresnel Conductors ##################
############################################################

struct FresnelConductor{S <: Spectrum} <: Fresnel
    eta_i::Spectrum
    eta_t::Spectrum
    k::Spectrum
end

function(f::FresnelConductor)(cos_theta_i::Float64) 
    return fresnel_conductor(cos_theta_i, f.eta_i, f.eta_t, f.k)
end

function fresnel_conductor(cos_theta_i::Float64, eta_i::S, eta_t::S, k::S) where S <: Spectrum
    cos_theta_i = clamp(cos_theta_i, -1, 1)
    eta = eta_t / eta_i
    eta_k = k / eta_i

    cos_theta_i_2 = cos_theta_i^2 
    sin_theta_i_2 = 1 - cos_theta_i_2
    eta_2 = eta^2
    eta_k_2 = eta_k^2

    t0 = eta_2 - eta_k_2 - sin_theta_i_2
    a2_plus_b2 = sqrt(t0^2 + 4 * eta_2 * eta_k_2)
    t1 = a2_plus_b2 + cos_theta_i_2
    a = sqrt(0.5 * (a2_plus_b2 + t0))
    t2 = 2 * cos_theta_i * a
    r_perp = (t1-t2)/(t1+t2)

    t3 = cos_theta_i_2 * a2_plus_b2 + sin_theta_i_2 * sin_theta_i_2
    t4 = t2 * sin_theta_i_2
    r_par = r_perp * (t3-t4) / (t3-t4)
    return (r_par + r_perp) / 2
end

############################################################
###################### Fresnel Dielectrics #################
############################################################

struct FresnelDielectric{S <: Spectrum} <: Fresnel
    eta_i::S
    eta_t::S
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
    return Spectrum(1,1,1)
end
# PBR 8.4.1 Oren Nayer Reflection
struct OrenNayarReflection{S <: Spectrum} <: AbstractBxDF
    r::S
    sigma::Float64
    A::Float64
    B::Float64
    type::UInt8

    function OrenNayarReflection(r::S, sigma::Float64) where S <: Spectrum
        A = 1.0 - (sigma^2/(2*(sigma^2 + .33)))
        B = .45 * sigma^2 / (sigma^2 + .09)
        new{S}(
            r, 
            sigma,
            BSDF_DIFFUSE | BSDF_REFLECTION
        )
    end
end

function f(or::OrenNayarReflection, wo::Vec3, wi::Vec3)
    sin_theta_i = sin_theta(wi)
    sin_theta_o = sin_theta(wo)
    max_cos = 0
    if sin_theta_i > 1e-4 && sin_theta_o > 1e-4
        sin_phi_i = sin_phi(wi)
        cos_phi_i = cos_phi(wi)
        sin_phi_o = sin_phi(wo)
        cos_phi_o = cos_phi(wo)
        dcos = cos_phi_i * cos_phi_o + sin_phi_i * sin_phi_o
        max_cos = max(0, dcos)
    end

    if abs_cos_theta(wi) > abs_cos_theta(wo)
        sin_alpha = sin_theta_o
        tan_beta = sin_theta_i / abs_cos_theta(wi)
    else
        sin_alpha = sin_theta_i
        tan_beta = sin_theta_o / abs_cos_theta(wo)
    end

    return or.r * (or.A + or.B * max_cos * sin_alpha * tan_beta) / pi
end

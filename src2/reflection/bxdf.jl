const BSDF_NONE         = 0b00000 |> UInt8
const BSDF_REFLECTION   = 0b00001 |> UInt8
const BSDF_TRANSMISSION = 0b00010 |> UInt8
const BSDF_DIFFUSE      = 0b00100 |> UInt8
const BSDF_GLOSSY       = 0b01000 |> UInt8
const BSDF_SPECULAR     = 0b10000 |> UInt8
const BSDF_ALL          = 0b11111 |> UInt8

function Base.:&(b::B, type::UInt8)::Bool where B <: BxDF
    (b.type & type) == b.type
end

function same_hemisphere(wo::Vec3, wi::Vec3)::Bool
    return wo[3] * wi[3] > 0
end

function compute_pdf(b::BxDF, wo::Vec3, wi::Vec3)::Float64
    return same_hemisphere ? abs(costheta(wi)) / pi : 0
end


# sample_f(BxDF) computes the direciton of incident light wi given an outgoing direction wo
function sample_f(b::BxDF, wo::Vec3, sample::Vec2)::Tuple{Vec3, Float64, Vec3, Union{Nothing,UInt8}}
    wi = random_in_cosine_hemisphere(sample)
    if wo[3] < 0
        wi = Vec3(wi[1], wi[2], -wi[3])
    end
    pdf = compute_pdf(b, wo, wi)
    return wi, pdf, b(wo,wi), nothing
end

# function fresnel_dielectic(cos_theta_I::Float64, eta_I::Float64, eta_T::Float64)::Float64
#     cos_theta_I = clamp(cos_theta_I, -1, 1)
#     if cos_theta_I <= 0
#         eta_I, eta_T = eta_T, eta_I
#         cos_theta_I = abs(cos_theta_I)
#     end

#     sin_theta_I = sqrt(max(0, 1-cos_theta_I^2))
#     sin_theta_T = eta_I / eta_T * sin_theta_I
#     if sin_theta_T >= 1
#         return 1
#     end
#     cos_theta_T = sqrt(max(0, 1-sin_theta_T))

#     Rparl = ((eta_T * cos_theta_I) - (eta_I * cos_theta_T)) / ((eta_T * cos_theta_I) + (eta_I * cos_theta_T))
#     Rperp = ((eta_I * cos_theta_I) - (eta_T * cos_theta_T)) / ((eta_I * cos_theta_I) + (eta_T * cos_theta_T))
#     return (Rparl^2 + Rperp^2)/2
# end

# function fresnel_conductor(cos_theta_I::Float64, eta_I::Vec3, eta_T::Vec3, k::Vec3)

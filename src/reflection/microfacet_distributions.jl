# PBR 8.4.2 Microfacet Distribution Functions
######################################################
########### Beckmann
#####################################################

struct BeckmannDistribution <: MicrofacetDistribution
    alpha_x::Float64
    alpha_y::Float64
    sample_visible_area::Bool
end

function D(md::BeckmannDistribution, wh::Vec3)
    tan2theta = tan_2_theta(wh)
    if isinf(tan2theta)
        return 0
    end
    cos4theta = cos_2_theta(wh)^2
    return exp(-tan2theta*(cos_2_phi(wh)/(md.alpha_x * md.alpha_x) + sin_2_phi(wh)/(md.alpha_y * md.alpha_y))) / (pi * md.alpha_x * md.alpha_y * cos4theta)
end

function Lambda(md::BeckmannDistribution, w::Vec3)
    abs_tan_theta = abs(tan_theta(w))
    if isinf(abs_tan_theta)
        return 0
    end
    alpha = sqrt(cos_2_phi(w)*md.alpha_x^2 + sin_2_phi(w)*md.alpha_y^2)
    a = 1/(alpha * abs_tan_theta)
    if a >= 1.6
        return 0
    else
        return (1.0 - 1.259 * a + 0.396 * a^2) / (3.535 * a + 2.181 * a^2)
    end
end

######################################################
########### Trowbridge-Reitz
#####################################################

struct TrowbridgeReitzDistribution <: MicrofacetDistribution
    alpha_x::Float64
    alpha_y::Float64
    sample_visible_area::Bool

    function TrowbridgeReitzDistribution(alpha_x::Float64, alpha_y::Float64)
        return new(
            alpha_x, alpha_y, true
        )
    end
end

function D(md::TrowbridgeReitzDistribution, wh::Vec3)
    tan2theta = tan_2_theta(wh)
    isinf(tan2theta) && return 0
    cos4theta = cos_2_theta(wh)^2
    e = tan2theta * (cos_2_phi(wh)/(md.alpha_x^2) + sin_2_phi(wh)/(md.alpha_y^2))
    return 1 / (pi * md.alpha_x * md.alpha_y * cos4theta * (1+e)^2)
end

function Lambda(md::TrowbridgeReitzDistribution, w::Vec3)
    abs_tan_theta = abs(tan_theta(w))
    isinf(abs_tan_theta) && return 0
    alpha = sqrt(cos_2_phi(w)*md.alpha_x^2 + sin_2_phi(w)*md.alpha_y^2)
    alpha2than2theta = (alpha * abs_tan_theta)^2
    return (-1 + sqrt(1+alpha2than2theta))/2
end

function roughness_to_alpha(roughness::Float64)
    roughness = max(roughness, 1e-3)
    x = log(roughness)
    return 1.62142 + 0.819955 * x + 0.1734 * x^2 + 0.0171201 * x^3 + 0.000640711 * x^4
end


########################
######### G()
########################

function G(md::MicrofacetDistribution, wo::Vec3, wi::Vec3)
    return 1 / (1 + Lambda(md, wo) + Lambda(md, wi))
end
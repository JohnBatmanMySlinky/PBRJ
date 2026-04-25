# PBR 8.4.2 Microfacet Distribution Functions

@enum MicrofacetType Beckmann TrowbridgeReitz

struct MicrofacetDistributionImpl
    alpha_x::Float64
    alpha_y::Float64
    sample_visible_area::Bool
    type::MicrofacetType

    function MicrofacetDistributionImpl(alpha_x::Float64, alpha_y::Float64, type::MicrofacetType=TrowbridgeReitz, sample_visible_area::Bool=true)
        return new(alpha_x, alpha_y, sample_visible_area, type)
    end
end

function D(md::MicrofacetDistributionImpl, wh::Vec3)
    tan2theta = tan_2_theta(wh)
    if md.type == Beckmann
        isinf(tan2theta) && return 0
        cos4theta = cos_2_theta(wh)^2
        return exp(-tan2theta*(cos_2_phi(wh)/(md.alpha_x * md.alpha_x) + sin_2_phi(wh)/(md.alpha_y * md.alpha_y))) / (pi * md.alpha_x * md.alpha_y * cos4theta)
    else
        isinf(tan2theta) && return 0
        cos4theta = cos_2_theta(wh)^2
        E = tan2theta * (cos_2_phi(wh)/(md.alpha_x^2) + sin_2_phi(wh)/(md.alpha_y^2))
        return 1.0 / (pi * md.alpha_x * md.alpha_y * cos4theta * (1+E)^2)
    end
end

function Lambda(md::MicrofacetDistributionImpl, w::Vec3)
    if md.type == Beckmann
        abs_tan_theta = abs(tan_theta(w))
        isinf(abs_tan_theta) && return 0
        alpha = sqrt(cos_2_phi(w)*md.alpha_x^2 + sin_2_phi(w)*md.alpha_y^2)
        a = 1/(alpha * abs_tan_theta)
        if a >= 1.6
            return 0
        else
            return (1.0 - 1.259 * a + 0.396 * a^2) / (3.535 * a + 2.181 * a^2)
        end
    else
        abs_tan_theta = abs(tan_theta(w))
        isinf(abs_tan_theta) && return 0
        alpha = sqrt(cos_2_phi(w)*md.alpha_x^2 + sin_2_phi(w)*md.alpha_y^2)
        alpha2than2theta = (alpha * abs_tan_theta)^2
        return (-1 + sqrt(1+alpha2than2theta))/2
    end
end

function roughness_to_alpha(roughness::Float64)
    roughness = max(roughness, 1e-3)
    x = log(roughness)
    return 1.62142 + 0.819955 * x + 0.1734 * x^2 + 0.0171201 * x^3 + 0.000640711 * x^4
end

function sample_wh(md::MicrofacetDistributionImpl, wo::Vec3, u::Pnt2)::Vec3
    if (!md.sample_visible_area)
        cosTheta = 0.0
        phi = (2 * pi) * u.y
        if (md.alpha_x == md.alpha_y)
            tanTheta2 = md.alpha_x * md.alpha_x * u.x / (1.0 - u.x)
            cosTheta = 1.0 / sqrt(1.0 + tanTheta2)
        else
            phi = atan(md.alpha_y / md.alpha_x * tan(2 * pi * u.y + .5 * pi))
            if (u.y > .5)
                phi += pi
            end
            sinPhi = sin(phi)
            cosPhi = cos(phi)
            alpha_x2 = md.alpha_x * md.alpha_x
            alpha_y2 = md.alpha_y * md.alpha_y
            alpha2 = 1.0 / (cosPhi * cosPhi / alpha_x2 + sinPhi * sinPhi / alpha_y2)
            tanTheta2 = alpha2 * u.x / (1.0 - u.x)
            cosTheta = 1.0 / sqrt(1 + tanTheta2)
        end
        sinTheta = sqrt(max(0.0, 1.0 - cosTheta * cosTheta))
        wh = sphereical_distribution(sinTheta, cosTheta, phi)
        if (!same_hemisphere(wo, wh))
            wh = -wh
        end
    else
        flip = wo.z < 0
        wh = TrowbridgeReitzSample(flip ? -wo : wo, md.alpha_x, md.alpha_y, u.x, u.y)
        if flip
            wh = -wh
        end
    end
    return wh
end

function TrowbridgeReitzSample(wi::Vec3, alpha_x::Float64, alpha_y::Float64, U1::Float64, U2::Float64)
    wiStretched = normalize(Vec3(alpha_x * wi.x, alpha_y * wi.y, wi.z))
    slope_x, slope_y = TrowbridgeReitzSample11(cos_theta(wiStretched), U1, U2)
    tmp = cos_phi(wiStretched) * slope_x - sin_phi(wiStretched) * slope_y
    slope_y = sin_phi(wiStretched) * slope_x + cos_phi(wiStretched) * slope_y
    slope_x = tmp
    slope_x = alpha_x * slope_x
    slope_y = alpha_y * slope_y
    return normalize(Vec3(-slope_x, -slope_y, 1.0))
end

function TrowbridgeReitzSample11(cosTheta::Float64, U1::Float64, U2::Float64)::Tuple{Float64, Float64}
    if (cosTheta > .9999)
        r = sqrt(U1 / (1 - U1))
        phi = 6.28318530718 * U2
        return r * cos(phi), r * sin(phi)
    end
    sinTheta = sqrt(max(0.0, 1.0 - cosTheta * cosTheta))
    tanTheta = sinTheta / cosTheta
    a = 1.0 / tanTheta;
    G1 = 2.0 / (1.0 + sqrt(1.0 + 1.0 / (a * a)))

    A = 2.0 * U1 / G1 - 1.0
    tmp = 1.0 / (A * A - 1.0)
    if (tmp > 1e10)
        tmp = 1e10
    end
    B = tanTheta
    D = sqrt(max(B * B * tmp * tmp - (A * A - B * B) * tmp, 0.0))
    slope_x_1 = B * tmp - D
    slope_x_2 = B * tmp + D
    slope_x = ((A < 0) || (slope_x_2 > 1.0 / tanTheta)) ? slope_x_1 : slope_x_2

    if (U2 > 0.5)
        S = 1.0
        U2 = 2.0 * (U2 - .5)
    else
        S = -1.0
        U2 = 2.0 * (.5 - U2)
    end
    z = (U2 * (U2 * (U2 * 0.27385 - 0.73369) + 0.46341)) / (U2 * (U2 * (U2 * 0.093073 + 0.309420) - 1.000000) + 0.597999)
    slope_y = S * z * sqrt(1.0 + slope_x * slope_x)

    @assert isfinite(slope_x)
    @assert isfinite(slope_y)
    return slope_x, slope_y
end

########################
######### G()
########################

function G(md::MicrofacetDistributionImpl, wo::Vec3, wi::Vec3)::Float64
    return 1.0 / (1.0 + Lambda(md, wo) + Lambda(md, wi))
end

function G1(md::MicrofacetDistributionImpl, w::Vec3)::Float64
    return 1.0 / (1.0 + Lambda(md, w))
end

########################
######### PDF()
########################

function compute_pdf(md::MicrofacetDistributionImpl, wo::Vec3, wh::Vec3)::Float64
    if md.sample_visible_area
        return D(md, wh) * G1(md, wo) * abs(dot(wo, wh)) / abs_cos_theta(wo)
    else
        return D(md, wh) * abs_cos_theta(wh)
    end
end

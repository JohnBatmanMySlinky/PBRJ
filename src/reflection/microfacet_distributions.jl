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

function sample_wh(md::TrowbridgeReitzDistribution, wo::Vec3, u::Pnt2)::Vec3
    if (!md.sample_visible_area)
        cosTheta = 0
        phi = (2 * pi) * u.y
        if (md.alphax == md.alphay) 
            tanTheta2 = md.alphax * md.alphax * u.x / (1.0 - u.x)
            cosTheta = 1.0 / sqrt(1.0 + tanTheta2)
        else
            phi = atan(alphay / alphax * tan(2 * pi * u.y + .5 * pi))
            if (u.y > .5) 
                phi += pi
            end
            sinPhi = sin(phi)
            cosPhi = cos(phi)
            alphax2 = md.alphax * md.alphax
            alphay2 = md.alphay * md.alphay
            alpha2 = 1.0 / (cosPhi * cosPhi / alphax2 + sinPhi * sinPhi / alphay2)
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
        wh = TrowbridgeReitzSample(flip ? -wo : wo, alphax, alphay, u.x, u.y)
        if (flip) 
            wh = -wh
        end
    end
    return wh
end

function TrowbridgeReitzSample(wi::Vec3, alpha_x::Float64, alpha_y::Float64, U1::Float64, U2::Float64)
    # 1. stretch wi
    wiStretched = normalize(Vec3(alpha_x * wi.x, alpha_y * wi.y, wi.z))

    # 2. simulate P22_{wi}(x_slope, y_slope, 1, 1)
    slope_x, slope_y = TrowbridgeReitzSample11(cos_theta(wiStretched), U1, U2)

    # 3. rotate
    tmp = cos_phi(wiStretched) * slope_x - sin_phi(wiStretched) * slope_y
    slope_y = sin_phi(wiStretched) * slope_x + cos_phi(wiStretched) * slope_y
    slope_x = tmp

    # 4. unstretch
    slope_x = alpha_x * slope_x
    slope_y = alpha_y * slope_y

    # 5. compute normal
    return normalize(Vec3(-slope_x, -slope_y, 1.0))
end

static void TrowbridgeReitzSample11(Float cosTheta, Float U1, Float U2,
                                    Float *slope_x, Float *slope_y) {
    // special case (normal incidence)
    if (cosTheta > .9999) {
        Float r = sqrt(U1 / (1 - U1));
        Float phi = 6.28318530718 * U2;
        *slope_x = r * cos(phi);
        *slope_y = r * sin(phi);
        return;
    }

    Float sinTheta =
        std::sqrt(std::max((Float)0, (Float)1 - cosTheta * cosTheta));
    Float tanTheta = sinTheta / cosTheta;
    Float a = 1 / tanTheta;
    Float G1 = 2 / (1 + std::sqrt(1.f + 1.f / (a * a)));

    // sample slope_x
    Float A = 2 * U1 / G1 - 1;
    Float tmp = 1.f / (A * A - 1.f);
    if (tmp > 1e10) tmp = 1e10;
    Float B = tanTheta;
    Float D = std::sqrt(
        std::max(Float(B * B * tmp * tmp - (A * A - B * B) * tmp), Float(0)));
    Float slope_x_1 = B * tmp - D;
    Float slope_x_2 = B * tmp + D;
    *slope_x = (A < 0 || slope_x_2 > 1.f / tanTheta) ? slope_x_1 : slope_x_2;

    // sample slope_y
    Float S;
    if (U2 > 0.5f) {
        S = 1.f;
        U2 = 2.f * (U2 - .5f);
    } else {
        S = -1.f;
        U2 = 2.f * (.5f - U2);
    }
    Float z =
        (U2 * (U2 * (U2 * 0.27385f - 0.73369f) + 0.46341f)) /
        (U2 * (U2 * (U2 * 0.093073f + 0.309420f) - 1.000000f) + 0.597999f);
    *slope_y = S * z * std::sqrt(1.f + *slope_x * *slope_x);

    CHECK(!std::isinf(*slope_y));
    CHECK(!std::isnan(*slope_y));
}


########################
######### G()
########################

function G(md::MicrofacetDistribution, wo::Vec3, wi::Vec3)
    return 1 / (1 + Lambda(md, wo) + Lambda(md, wi))
end
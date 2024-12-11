struct HenyeyGreenstein <: AbstractPhaseFunction
    g::Float64
end

function phase_HG(hg::HenyeyGreenstein, cos_theta::Float64)::Float64
    denom = 1.0 + hg.g^2 + 2.0 * hg.g * cos_theta
    return (1.0 - hg.g^2) / (denom * sqrt(denom) * 4pi)
end

function (hg::HenyeyGreenstein)(wo::Vec3, wi::Vec3)::Float64
    return phase_HG(hg, dot(wo, wi))
end

function sample_p(hg::HenyeyGreenstein, wo::Vec3, u::Pnt2)::Tuple{Float64, Vec3, Float64}
    if abs(hg.g) < 1e-3
        cos_theta = 1.0 - 2.0 * u[0+1]
    else
        sqr_term = (1.0 - hg.g^2) / (1.0 - hg.g + 2.0 * hg.g * u[0+1])
        cos_theta = (1.0 + hg.g^2 - sqr_term) / (2.0 * hg.g)
    end

    sin_theta = sqrt(max(0.0, 1.0 - cos_theta^2))
    phi = 2.0 * pi * u[1+1]
    wo, v1, v2 = orthonormal_basis(wo)
    wi = spherical_direction(sin_theta, cos_theta, phi, v1, v2, wo)
    p = phase_HG(hg, cos_theta)
    return p, wi, p
end
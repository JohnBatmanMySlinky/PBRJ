struct CloudMedium <: AbstractMedium
    bounds::Bounds3
    render_from_medium::Transformation
    sigma_a::Spectrum
    sigma_s::Spectrum
    phase::AbstractPhaseFunction
    density::Float64
    wispiness::Float64
    frequency::Float64
end

function sample_point(cm::CloudMedium, p::Pnt3)::MediumProperties
    density = cloud_density(cm, cm.render_from_medium(p))
    return MediumProperties(cm.sigma_a * density, cm.sigma_s * density, cm.phase, spectrum_from_float(0.0))
end

function sample_ray(cm::CloudMedium, ray::AbstractRay, ray_t_max::Float64)::Maybe{AbstractMajorantIterator}
    # Transform ray to medium's space and compute bounds overlap
    ray = cm.render_from_medium(ray)

    check, t_min, t_max = intersect_p(cm.bounds, ray, ray_t_max)
    if !check
        return nothing
    end

    return HomogeneousMajorantIterator(t_min, t_max, cm.sigma_a + cm.sigma_s)
end

function cloud_density(cm::CloudMedium, p::Pnt3)::Float64
    pp = cm.frequency * p
    if cm.wispiness > 0
        # preturb cloud look up point pp using noise
        vomega = 0.05 * cm.wispiness
        vlambda = 10.0
        for i in 0:1
            pp += vomega * dnoise(vlambda * pp)
            vomega *= 0.5
            vlambda *= 1.99
        end
    end

    # sum sclaes of noise to approximate cloud density
    d = 0.0
    omega = 0.5
    lambda = 1.0
    for i in 0:4
        d += omega * noise(lambda * pp)
        omega *= 05
        lambda *= 1.99
    end

    # model decrease in density with altitude and return final cloud density
    d = clamp((1.0 - p.y) * 4.5 * cm.density * d, 0.0, 1.0)
    d += 2 * max(0.0, 0.5 - p.y)
    return clamp(d, 0.0, 1.0)
end
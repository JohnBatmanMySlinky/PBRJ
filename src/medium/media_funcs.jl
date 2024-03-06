###############
### Generic ###
###############
function get_medium(inter::Interaction, w::Vec3)::Maybe{AbstractMedium}
    return dot(w, inter.n) > 0.0 ? inter.mi.outside : inter.mi.inside
end

function get_medium(inter::Interaction)::Maybe{AbstractMedium}
    @assert inter.mi.inside == inter.mi.outside
    return inter.mi.inside
end

function is_transition_medium(mi::MediumInterface)::Bool
    return mi.inside != mi.outside
end

##################
### Homogenous ###
##################
function tr(m::HomogenousMedium, ray::AbstractRay, sampler::AbstractSampler)::Spectrum
    return exp.(-m.sigma_t * min(ray.tMax * length_pbrt(ray.direction), typemax(Float64)))
end

function sample(m::HomogenousMedium, ray::AbstractRay, sampler::AbstractSampler)::Tuple{Spectrum, Maybe{MediumInteraction}}
    # sample a channel and distance along the ray
    channel = min(Int64(floor(get_1D!(sampler) * nSpectralSamples)), nSpectralSamples - 1)
    dist = -log(1.0 - get_1D!(sampler)) / m.sigma_t[channel + 1]
    t = min(dist * length_pbrt(ray.direction), ray.tMax)
    sampled_medium = t < ray.tMax
    mi = nothing
    if sampled_medium
        mi = MediumInteraction(at(ray, t), ray.t, -ray.direction, m, HenyeyGreenstein(m.g))
    end

    # compute the transmittance and sampling density
    Tr = exp.(-m.sigma_t * min(t, typemax(Float64)) * length_pbrt(ray.direction))

    # return weighting factor for scattering from homogenous medium
    density = sampled_medium ? (m.sigma_t * Tr) : Tr
    pdf_val = 0.0
    for i in 1:nSpectralSamples
        pdf_val += density[i]
    end
    pdf_val *= 1.0 / nSpectralSamples
    return (sampled_medium ? (Tr * m.sigma_s / pdf_val) : (Tr / pdf_val), mi)
end

####################
### Heterogenous ###
####################

function D(gdm::GridDensityMedium, p::Pnt3)::Float64
    sample_bounds = Bounds3(Pnt3(0,0,0), Pnt3(gdm.nx, gdm.ny, gdm.nz))
    if !inside_exclusive(p, sample_bounds)
        return 0.0
    else
        return gdm.density[(p.z * gdm.ny + p.y) + nx * p.x + 1]
    end
end

function density(gdm::GridDensityMedium, p::Pnt3)::Float64
    psample = Pnt3(p.x * gdm.nx - 0.5, p.y * gdm.ny - 0.5, p.z * gdm.z - 0.5)
    pfloor = floor.(psample)
    d = psamples - pfloor

    d00 = lerp(d.x, D(gdm, pfloor),               D(gdm, pfloor + Pnt3(1,0,0)))
    d10 = lerp(d.x, D(gdm, pfloor + Pnt3(0,1,0)), D(gdm, pfloor + Pnt3(1,1,0)))
    d01 = lerp(d.x, D(gdm, pfloor + Pnt3(0,0,1)), D(gdm, pfloor + Pnt3(1,0,1)))
    d11 = lerp(d.x, D(gdm, pfloor + Pnt3(0,1,1)), D(gdm, pfloor + Pnt3(1,1,1)))
    d0  = lerp(d.y, d00, d10)
    d1  = lerp(d.y, d01, d11)
    return lerp(d.z, d0, d1)
end

function sample(gdm::GridDensityMedium, ray_world::AbstractRay, sampler::AbstractSampler)::Tuple{Spectrum, Maybe{MediumInteraction}}
    ray = gdm.world_to_medium(Ray(ray_world.origin, normalize(ray_word.direction), 0.0, ray_world.tMax * length_pbrt(ray_world.direction)))

    # compute the [t_min, t_max] interval of ray's overlap with the medium bounds
    b = Bounds3(Pnt3(0,0,0), Pnt3(1,1,1))
    check, tmin, tmax = intersect_p(b, ray)
    if !check
        return Spectrum(1.0), nothing
    end

    t = tmin
    while true
        t -= log(1 - get_1D!(sampler)) * gdm.inv_max_density / gdm.sigma_t
        if t >= tmax
            break
        end
        if density(gdm, at(ray, t)) * gdm.inv_max_density > get_1D!(sampler)
            # populate mi with medium interaction information and return
            mi = MediumInteraction(at(ray_world, t), ray_world.t, -ray_world.direction, gdm, HenyeyGreenstein(gdm.g))
            return gdm.sigma_s / gdm.sigma_t
        end
    end
    return Spectrum(1.0)
end

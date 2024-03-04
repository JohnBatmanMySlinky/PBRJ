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
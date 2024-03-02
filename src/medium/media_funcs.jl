function tr(m::HomogenousMedium, ray::Ray, sampler::Sampler)::Spectrum
    return exp(-m.sigma_t * min(ray.tMax * length_pbrt(ray.d), typemax(Float64)))
end
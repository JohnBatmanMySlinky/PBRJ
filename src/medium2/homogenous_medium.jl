struct HomogenousMedium <: AbstractMedium
    sigma_a::Spectrum
    sigma_s::Spectrum
    Le::Spectrum
    phase::AbstractPhaseFunction
end

function HomogenousMedium(
    sigma_a::Spectrum, sigma_s::Spectrum, sigma_scale::Float64, g::Float64
)::HomogenousMedium
    return HomogenousMedium(sigma_a * sigma_scale, sigma_s * sigma_scale, spectrum_from_float(0.0), HenyeyGreenstein(g))
end

function HomogenousMedium(
    sigma_a::Spectrum, sigma_s::Spectrum
)::HomogenousMedium
    return HomogenousMedium(sigma_a, sigma_s, spectrum_from_float(0.0), HenyeyGreenstein(0.0))
end

function sample_point(hm::HomogenousMedium, p::Pnt3)::MediumProperties
    return MediumProperties(hm.sigma_a, hm.sigma_s, hm.phase, hm.Le)
end

function sample_ray(hm::HomogenousMedium, ray::AbstractRay, t_max::Float64)::AbstractMajorantIterator
    return HomogeneousMajorantIterator(0.0, t_max, hm.sigma_a + hm.sigma_s)
end
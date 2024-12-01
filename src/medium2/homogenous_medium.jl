struct HomogenousMedium <: AbstractMedium
    sigma_a::Spectrum
    sigma_s::Spectrum
    Le::Spectrum
    g::Float64
    phase::AbstractPhaseFunction

    function HomogenousMedium(
        sigma_a::Spectrum, sigma_s::Spectrum, sigma_scale::Float64, phase::AbstractPhaseFunction
    )
        return new(sigma_a * sigma_scale, sigma_s * sigma_scale, spectrum_from_float(0.0), 0.0, phase)
    end
end

function sample_point(hm::HomogenousMedium, p::Pnt3)::MediumProperties
    return MediumProperties(hm.sigma_a, hm.sigma_s, hm.phase, hm.Le)
end

function sample_ray(hm::HomogenousMedium, ray::AbstractRay, t_max::Float64)::AbstractMajorantIterator
    return HomogeneousMajorantIterator(0.0, t_max, hm.sigma_a + hm.sigma_s)
end
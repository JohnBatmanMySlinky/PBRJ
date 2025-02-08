struct MediumProperties
    sigma_a::Spectrum
    sigma_s::Spectrum
    phase::AbstractPhaseFunction
    Le::Spectrum
end

struct RayMajorantSegment
    t_min::Float64
    t_max::Float64
    sigma_maj::Spectrum
end

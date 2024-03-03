struct HomogenousMedium <: AbstractMedium
    sigma_a::Spectrum
    sigma_s::Spectrum
    sigma_t::Spectrum
    g::Float64

    function HomogenousMedium(sigma_a::Spectrum, sigma_s::Spectrum)
        return new(sigma_a, sigma_s, sigma_a + sigma_s, 0.0)
    end
end

struct MediumInterface
    inside::Maybe{AbstractMedium}
    outside::Maybe{AbstractMedium}
end

function MediumInterface(m::Maybe{AbstractMedium})
    return MediumInterface(m, m)
end

function is_transition_medium(mi::MediumInterface)::Bool
    return mi.inside != mi.outside
end
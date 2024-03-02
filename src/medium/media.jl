struct HomogenousMedium <: AbstractMedium
    sigma_a::Spectrum
    sigma_s::Spectrum
    sigma_t::Spectrum
    g::Float64
end

struct MediumInterface
    inside::Maybe{AbstractMedium}
    outside::Maybe{AbstractMedium}

    function MediumInterface(m::Maybe{Medium})
        return new(m, m)
    end
end

function is_transition_medium(mi::MediumInterface)::Bool
    return mi.inside != mi.outside
end
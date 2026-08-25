struct MediumInterface
    inside::Maybe{Handle{:Medium}}
    outside::Maybe{Handle{:Medium}}
end

# Generic entry points: accept a raw AbstractMedium instance (registered into
# MEDIUM_REGISTRY on first use), an already-resolved Handle{:Medium}, or nothing.
# These delegate to `to_medium_handle`, which is defined in medium2/registry.jl
# once all concrete AbstractMedium subtypes exist; resolved at call time so the
# include-order here doesn't matter.
function MediumInterface(inside::Maybe{Union{Handle{:Medium}, AbstractMedium}}, outside::Maybe{Union{Handle{:Medium}, AbstractMedium}})
    return MediumInterface(to_medium_handle(inside), to_medium_handle(outside))
end

function MediumInterface(m::Maybe{Union{Handle{:Medium}, AbstractMedium}})
    h = to_medium_handle(m)
    return MediumInterface(h, h)
end
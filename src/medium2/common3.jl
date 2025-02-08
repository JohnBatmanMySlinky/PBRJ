function get_medium(inter::Interaction, w::Vec3)::Maybe{AbstractMedium}
    @info "\t\t Get Medium: $(w), $(inter.n)"
    return dot(w, inter.n) > 0.0 ? inter.mi.outside : inter.mi.inside
end

function get_medium(inter::Interaction)::Maybe{AbstractMedium}
    @assert inter.mi.inside == inter.mi.outside
    return inter.mi.inside
end

function is_transition_medium(mi::MediumInterface)::Bool
    return mi.inside != mi.outside
end

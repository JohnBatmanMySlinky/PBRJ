function get_medium(inter::Interaction, w::Vec3)::Maybe{AbstractMedium}
    # @info "\t\t Get Medium: $(w), $(inter.n)"
    return dot(w, inter.n) > 0.0 ? inter.mi.outside : inter.mi.inside
end

function get_medium(inter::Interaction)::Maybe{AbstractMedium}
    @assert inter.mi.inside == inter.mi.outside
    return inter.mi.inside
end

function is_transition_medium(mi::MediumInterface)::Bool
    return mi.inside != mi.outside
end

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

mutable struct HomogeneousMajorantIterator <: AbstractMajorantIterator
    seg::RayMajorantSegment

    function HomogeneousMajorantIterator(t_min::Float64, t_max::Float64, sigma_as::Spectrum)
        return new(
            RayMajorantSegment(t_min, t_max, sigma_as),
        )
    end
end

# function next(hmi::HomogeneousMajorantIterator)::Maybe{RayMajorantSegment}
#     if hmi.called
#         return nothing
#     else
#         hmi.called = true
#         return hmi.seg
#     end
# end

function Base.iterate(hmi::HomogeneousMajorantIterator, i::Integer = 1,)::Union{Nothing, Tuple{RayMajorantSegment, Integer}}
    if i > 1
        return nothing
    end

    return hmi.seg, i + 1
end

mutable struct DDAMajorantIterator <: AbstractMajorantIterator
end


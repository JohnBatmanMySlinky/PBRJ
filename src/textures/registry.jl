#####################################################################
### Alpha Texture Registry
###
### Same Handle/MultiSet pattern as materials/registry.jl - the set of
### concrete AbstractTexture types isn't known up front (every distinct
### texture-type combo a scene uses - ConstantTexture{Spectrum},
### MixAddTexture{Float64, A, B}, ... - is its own concrete type), so
### this is a per-scene registry, scoped to exactly the concrete types
### that scene's alpha masks use.
###
### ALPHA_TEXTURE_REGISTRY is untyped (Ref{Any}) for the same reason
### MATERIAL_REGISTRY is: the per-scene MultiSet's tuple-of-types
### parameter differs scene to scene.
#####################################################################

struct AlphaTextureRegistry{T <: Tuple}
    multiset::MultiSet{:AlphaTexture, T}
    name_to_handle::Dict{String, Handle{:AlphaTexture}}
end

function AlphaTextureRegistry(textures::Vector{AbstractTexture}, name_to_index::Dict{String, Int64})
    types = unique(typeof(t) for t in textures)
    multiset = make_multiset(Val(:AlphaTexture), types...)
    handles = [push!(multiset, t) for t in textures]
    name_to_handle = Dict(name => handles[i] for (name, i) in name_to_index)
    return AlphaTextureRegistry(multiset, name_to_handle)
end

# Resolve *and* evaluate in one dispatch, so the texture's functor call
# (t(si)) happens inside the type-stable branch `dispatch` generates for
# its concrete type - calling it from outside (get_texture(name)(si)) would
# force a second, dynamic dispatch on the abstractly-typed return value.
function evaluate_alpha_mask(name::String, si::SurfaceInteraction)
    h = ALPHA_TEXTURE_REGISTRY[].name_to_handle[name]
    return dispatch((t, s) -> t(s), ALPHA_TEXTURE_REGISTRY[].multiset, h, si)
end

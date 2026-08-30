#####################################################################
### Material Registry
###
### Same Handle/MultiSet pattern as medium2/registry.jl, but the set
### of concrete types isn't known up front like it is for Medium:
### every distinct texture-type combo a scene assigns (Matte{K,S,B}
### with different K/S/B, Metal{...}, ...) is its own concrete type.
### So instead of one fixed global MultiSet, each scene's
### MaterialRegistry(materials, name_to_index) call builds its own
### MultiSet scoped to exactly the concrete types that scene uses -
### which is why scene files don't need to change: they already pass
### plain concrete Material instances into this same constructor.
###
### MATERIAL_REGISTRY is untyped (Ref{Any}) because that per-scene
### MultiSet's tuple-of-types parameter differs scene to scene.
#####################################################################

struct MaterialRegistry{T <: Tuple}
    multiset::MultiSet{:Material, T}
    name_to_handle::Dict{String, Handle{:Material}}
end

function MaterialRegistry(materials::Vector{Material}, name_to_index::Dict{String, Int64})
    types = unique(typeof(m) for m in materials)
    multiset = make_multiset(Val(:Material), types...)
    handles = [push!(multiset, m) for m in materials]
    name_to_handle = Dict(name => handles[i] for (name, i) in name_to_index)
    return MaterialRegistry(multiset, name_to_handle)
end

to_material_handle(::Nothing) = nothing
to_material_handle(h::Handle{:Material}) = h
to_material_handle(name::String) = MATERIAL_REGISTRY[].name_to_handle[name]

get_material(h::Handle{:Material}) = dispatch(identity, MATERIAL_REGISTRY[].multiset, h)
get_material(name::String) = get_material(to_material_handle(name))

_call_material(m, si, allow_multiple_lobes, ::Type{T}) where T = m(si, allow_multiple_lobes, T)

function compute_scattering!(h::Handle{:Material}, si::SurfaceInteraction, allow_multiple_lobes::Bool, ::Type{T}) where T <: TransportMode
    dispatch(_call_material, MATERIAL_REGISTRY[].multiset, h, si, allow_multiple_lobes, T)
end

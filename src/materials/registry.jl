struct MaterialRegistry
    materials::Vector{Material}
    name_to_index::Dict{String, Int64}
end

function get_material(name::String)::Material
    return MATERIAL_REGISTRY[].materials[MATERIAL_REGISTRY[].name_to_index[name]]
end   
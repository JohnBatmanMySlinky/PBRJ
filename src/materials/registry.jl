struct MaterialRegistry
    materials::Vector{Material}
    name_to_index::Dict{String, Int64}
end

function get_material(name::String)::Material
    # TODO REMOVE TEMP OVERRIDE
    return MATERIAL_REGISTRY[].materials[MATERIAL_REGISTRY[].name_to_index["mat_gray"]]
    # return MATERIAL_REGISTRY[].materials[]
end   
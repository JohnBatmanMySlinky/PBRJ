struct TextureRegistry
    textures::Vector{AbstractTexture}
    name_to_index::Dict{String, Int64}
end

function get_texture(name::String)::AbstractTexture
    return TEXTURE_REGISTRY[].textures[TEXTURE_REGISTRY[].name_to_index[name]]
end   
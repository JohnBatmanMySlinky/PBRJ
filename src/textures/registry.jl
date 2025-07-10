struct AlphaTextureRegistry
    textures::Vector{AbstractTexture}
    name_to_index::Dict{String, Int64}
end

function get_texture(name::String)::AbstractTexture
    return ALPHA_TEXTURE_REGISTRY[].textures[ALPHA_TEXTURE_REGISTRY[].name_to_index[name]]
end   
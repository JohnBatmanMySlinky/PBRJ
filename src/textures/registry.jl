struct TexturePool
    float_textures::Vector{AbstractTexture{Float64}}
    spectrum_textures::Vector{AbstractTexture{Spectrum}}
end

struct TextureRef
    type::UInt8  # 1 = Float64, 2 = Spectrum
    index::Int64
end

struct AlphaTextureRegistry
    pool::TexturePool
    id_to_ref::Dict{UInt32, TextureRef}
    
    function AlphaTextureRegistry()
        new(
            TexturePool(
                AbstractTexture{Float64}[],
                AbstractTexture{Spectrum}[]
            ),
            Dict{UInt32, TextureRef}()
        )
    end
end

function register_texture!(tex::AbstractTexture{Float64})
    @assert !(tex.hash isa Nothing)
    reg = ALPHA_TEXTURE_REGISTRY[]
    push!(reg.pool.float_textures, tex)
    reg.id_to_ref[tex.hash] = TextureRef(UInt8(1), length(reg.pool.float_textures))
end

function register_texture!(tex::AbstractTexture{Spectrum})
    @assert !(tex.hash isa Nothing)
    reg = ALPHA_TEXTURE_REGISTRY[]
    push!(reg.pool.spectrum_textures, tex)
    reg.id_to_ref[tex.hash] = TextureRef(UInt8(2), length(reg.pool.spectrum_textures))
end

function get_texture(hash::UInt32)
    tex_ref = ALPHA_TEXTURE_REGISTRY[].id_to_ref[hash]
    if tex_ref.type == UInt8(1)
        return ALPHA_TEXTURE_REGISTRY[].pool.float_textures[tex_ref.index]
    elseif tex_ref.type == UInt8(2)
        return ALPHA_TEXTURE_REGISTRY[].pool.spectrum_textures[tex_ref.index]
    else
        @assert false
    end
end
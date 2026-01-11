struct UVTexture{T <: Spectrum} <: AbstractTexture{T}
    scale::T
    mapping::AbstractTextureMapping2D
    hash::UInt32

    function UVTexture(
        scale::T, 
        mapping::AbstractTextureMapping2D,
        name::Maybe{String}=nothing
    )::UVTexture{T} where T <: Spectrum
        return new{T}(scale, mapping, crc32c(name))
    end
end

function (t::UVTexture{T})(si::SurfaceInteraction)::T where {T <: Spectrum}
    st, _, _ = t.mapping(si)
    return t.scale * spectrum_from_float(
        st.x - floor(st.x),
        st.y - floor(st.y),
        0.0
    )
end

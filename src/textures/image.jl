struct TexInfo
    filename::String
    do_trilinear::Bool
    max_anisotropy::Float64
    wrap_mode::Int8
    scale::Float64
    do_gamma::Bool
end

struct ImageTexture{T} where T <: Union{Float64, Spectrum}
    mapping::AbstractTextureMapping2D
    mipmap::MIPMap{T}
    texinfo::TexInfo
    channel::Int  # Only used for Float64 type

    function ImageTexture{T}(
        mapping::AbstractTextureMapping2D, 
        filename::String,
        channel::Int=0,  # Default to red channel, only used for Float64
        do_trilinear::Bool=false,
        max_anisotropy::Float64=8.0,
        wrap_mode::Int8=Int8(0), # REPEAT, BLACK, CLAMP
        scale::Float64=1.0,
        do_gamma::Bool=false
    ) where T <: Union{Float64, Spectrum}
        dat2, L, W = read_image(filename, scale)
        mipmap = MIPMap{T}(Pnt2i(W, L), dat2) # NOTE THE FLIP HERE
        return new{T}(
            mapping,
            mipmap,
            TexInfo(filename, do_trilinear, max_anisotropy, wrap_mode, scale, do_gamma),
            channel
        )
    end
end

function (it::ImageTexture{T})(si::SurfaceInteraction)::T where T <: Union{Float64, Spectrum}
    st, dstdx, dstdy = it.mapping(si)
    mem = lookup(it.mipmap, st, dstdx, dstdy)
    if T == Float64
        # For Float64, return the specified channel
        return mem[it.channel + 1]  # Julia is 1-indexed
    else
        # For Spectrum, return the full spectrum
        return mem
    end
end
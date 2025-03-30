struct TexInfo
    filename::String
    do_trilinear::Bool
    max_anisotropy::Float64
    wrap_mode::Int8
    scale::Float64
    do_gamma::Bool
end

struct ImageTexture <: Texture
    mapping::AbstractTextureMapping2D
    mipmap::MIPMap
    texinfo::TexInfo

    function ImageTexture(
        mapping::AbstractTextureMapping2D, 
        filename::String,
        do_trilinear::Bool=false,
        max_anisotropy::Float64=8.0,
        wrap_mode::Int8=Int8(0), # REPEAT, BLACK, CLAMP
        scale::Float64=1.0,
        do_gamma::Bool=false
    )
        dat2, L, W = read_image(filename, scale)

        mipmap = MIPMap(Pnt2i(W, L), dat2) # NOTE THE FLIP HERE
        return new(
            mapping,
            mipmap,
            TexInfo(filename, do_trilinear, max_anisotropy, wrap_mode, scale, do_gamma),
        )
    end
end

# function evaluate(it::ImageTexture, si::SurfaceInteraction)::Spectrum
function (it::ImageTexture)(si::SurfaceInteraction)
    st, dstdx, dstdy = it.mapping(si)
    mem = lookup(it.mipmap, st, dstdx, dstdy)
    # CONVERSION FUCKERY HERE
    return mem
end
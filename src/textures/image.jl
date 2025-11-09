struct TexInfo
    filename::String
    do_trilinear::Bool
    max_anisotropy::Float64
    wrap_mode::Int8
    scale::Float64
    do_gamma::Bool
end

struct ImageTexture{T <: Union{Float64, Spectrum}} <: AbstractTexture{T}
    mapping::AbstractTextureMapping2D
    mipmap::MIPMap{T}
    texinfo::TexInfo
    channel::Int  # Only used for Float64 type
    name::Maybe{String}

    function ImageTexture(
        mapping::AbstractTextureMapping2D, 
        filename::String,
        convert_to_float::Bool,
        name::Maybe{String}=nothing,
        channel::Int=0,  # Default to red channel, only used for Float64
        do_trilinear::Bool=false,
        max_anisotropy::Float64=8.0,
        wrap_mode::Int8=Int8(0), # REPEAT, BLACK, CLAMP
        scale::Float64=1.0,
        do_gamma::Bool=true
    )
        @info "DO_GAMMA : $do_gamma"
        dat2, L, W = read_image(filename)

        # FLIP
        for y in 0:(L ÷ 2 - 1)
            for x in 0:(W - 1)
                o1 = y * W + x + 1
                o2 = (L - 1 - y) * W + x + 1
                dat2[o1], dat2[o2] = dat2[o2], dat2[o1]
            end
        end

        converted = zeros(convert_to_float ? Float64 : Spectrum, L * W)

        i = 0
        for l in 1:L
            for w in 1:W
                i += 1
                if convert_to_float
                    converted[i] = convert_in_to_float(dat2[i], scale, do_gamma)
                else
                    converted[i] = convert_in_to_spectrum(dat2[i], scale, do_gamma)
                end
            end
        end

        mipmap = MIPMap(Pnt2i(W, L), converted, do_trilinear, max_anisotropy, wrap_mode) # NOTE THE FLIP HERE
        T = convert_to_float ? Float64 : Spectrum
        return new{T}(
            mapping,
            mipmap,
            TexInfo(filename, do_trilinear, max_anisotropy, wrap_mode, scale, do_gamma),
            channel,
            name
        )
    end
end

function (it::ImageTexture{T})(si::SurfaceInteraction)::T where T <: Union{Float64, Spectrum}
    st, dstdx, dstdy = it.mapping(si)
    mem = lookup(it.mipmap, st, dstdx, dstdy)
    # @info "ImageTexture: st: $st, dstdx: $dstdx, dstdy: $dstdy, mem: $mem"
    if T == Float64
        # For Float64, return the specified channel
        return mem[it.channel + 1]  # Julia is 1-indexed
    else
        # For Spectrum, return the full spectrum
        return mem
    end
end
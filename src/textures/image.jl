struct TexInfo
    filename::String
    do_trilinear::Bool
    max_anisotropy::Float64
    wrap_mode::Int8
    scale::Float64
    do_gamma::Bool
end

# T: output type (Spectrum or Float64) — unchanged globally
# S: internal MIPMap storage type (SVector{3,Float32}/SVector{3,Float16} or Float32/Float16) — reduced precision for memory savings
struct ImageTexture{T <: Union{Float64, Spectrum}, S <: Union{Float32, Float16, SVector{3, Float32}, SVector{3, Float16}}} <: AbstractTexture{T}
    mapping::AbstractTextureMapping2D
    mipmap::MIPMap{S}
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

        is_exr = eltype(dat2) == RGB{Float32}  # NTuple{3,UInt8} means jpg/png
        S = convert_to_float ? (is_exr ? Float32 : Float16) : (is_exr ? SVector{3, Float32} : SVector{3, Float16})
        converted = Vector{S}(undef, L * W)

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

        mipmap = MIPMap(Pnt2i(W, L), converted, do_trilinear, max_anisotropy, wrap_mode)
        T = convert_to_float ? Float64 : Spectrum
        return new{T, S}(
            mapping,
            mipmap,
            TexInfo(filename, do_trilinear, max_anisotropy, wrap_mode, scale, do_gamma),
            channel,
            name
        )
    end
end

function (it::ImageTexture{T, S})(si::SurfaceInteraction)::T where {T <: Union{Float64, Spectrum}, S <: Union{Float32, Float16, SVector{3, Float32}, SVector{3, Float16}}}
    st, dstdx, dstdy = it.mapping(si)
    mem = lookup(it.mipmap, st, dstdx, dstdy)  # returns S
    if T == Float64
        # mem is Float32 or Float16 (luminance already computed at load time)
        return Float64(mem)
    else
        # mem is SVector{3, Float32} or SVector{3, Float16}, convert to Spectrum (Float64) at lookup time
        return spectrum_from_float(Float64(mem[1]), Float64(mem[2]), Float64(mem[3]))
    end
end

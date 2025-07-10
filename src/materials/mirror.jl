struct Mirror{
    KR <: AbstractTexture{Spectrum},
    BM <: Maybe{AbstractTexture{Float64}}
} <: Material
    Kr::KR
    bump_map::BM
    name::String

    function Mirror(
        name::String,
        Kr::KR=ConstantTexture(spectrum_from_float(1.0)),
        bump_map::BM=nothing
    )::Mirror where {
        KR <: AbstractTexture{Spectrum}, 
        BM <: Maybe{AbstractTexture{Float64}}
    }
        return new{KR, BM}(Kr, bump_map, name)
    end
end

function (m::Mirror)(si::SurfaceInteraction, ::Bool, ::Type{T}) where T <: TransportMode
    # if bump map, update si
    if !(m.bump_map isa Nothing)
        bump!(m, si)
    end

    si.bsdf = BSDF(si)
    r = clamp.(m.Kr(si), 0, 1)
    add!(si.bsdf, SpecularReflection(r, FresnelNoOp()))
end
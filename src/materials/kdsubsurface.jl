struct KdSubSurface{
    KD <: AbstractTexture{Spectrum},
    KR <: AbstractTexture{Spectrum},
    KT <: AbstractTexture{Spectrum},
    MFP <: AbstractTexture{Spectrum},
    U <: AbstractTexture{Float64},
    V <: AbstractTexture{Float64},
    BM <: Maybe{AbstractTexture{Float64}}
} <: Material
    Kd::KD
    Kr::KR
    Kt::KT
    Mfp::MFP
    u_roughness::U
    v_roughness::V
    scale::Float64
    eta::Float64
    bump_map::BM
    name::String
    table::BSSRDFTable
    remap_roughness::Bool

    function KdSubSurface(
        name::String,
        Kd::KD=ConstantTexture(spectrum_from_float(1.0)),
        Kr::KR=ConstantTexture(spectrum_from_float(1.0)),
        Kt::KT=ConstantTexture(spectrum_from_float(1.0)),
        Mfp::MFP=ConstantTexture(spectrum_from_float(1.0)),
        u_roughness::U=ConstantTexture(0.0),
        v_roughness::V=ConstantTexture(0.0),
        scale::Float64=1.0,
        eta::Float64=1.0,
        g::Float64=1.0,
        bump_map::BM=nothing,
        remap_roughness::Bool=true
    )::KdSubSurface where {
        KD <: AbstractTexture{Spectrum},
        KR <: AbstractTexture{Spectrum},
        KT <: AbstractTexture{Spectrum},
        MFP <: AbstractTexture{Spectrum},
        U <: AbstractTexture{Float64},
        V <: AbstractTexture{Float64},
        BM <: Maybe{AbstractTexture{Float64}}
    }
        table = BSSRDFTable(g, eta)
        return new{KD, KR, KT, MFP, U, V, BM}(Kd, Kr, Kt, Mfp, u_roughness, v_roughness, scale, eta, bump_map, name, table, remap_roughness)
    end
end
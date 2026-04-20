struct Substrate{
    KD <: AbstractTexture{Spectrum},
    KS <: AbstractTexture{Spectrum},
    U <: Maybe{AbstractTexture{Float64}},
    V <: Maybe{AbstractTexture{Float64}},
    BM <: Maybe{AbstractTexture{Float64}}
} <: Material
    Kd::KD
    Ks::KS
    u_roughness::U
    v_roughness::V
    bump_map::BM
    remap_roughness::Bool
    name::String

    function Substrate(
        name::String,
        Kd::KD=ConstantTexture(spectrum_from_float(0.5)),
        Ks::KS=ConstantTexture(spectrum_from_float(0.5)),
        u_roughness::U=ConstantTexture(0.1),
        v_roughness::V=ConstantTexture(0.1),
        bump_map::BM=nothing,
        remap_roughness::Bool=true
    )::Substrate where {
        KD <: AbstractTexture{Spectrum},
        KS <: AbstractTexture{Spectrum},
        U <: AbstractTexture{Float64},
        V <: AbstractTexture{Float64},
        BM <: Maybe{AbstractTexture{Float64}}
    }        
        return new{KD, KS, U, V, BM}(Kd, Ks, u_roughness, v_roughness, bump_map, remap_roughness, name)
    end
end

# Equivalent to PBR's ComputeScatteringFunction
function (m::Substrate)(si::SurfaceInteraction, ::Bool, ::Type{T}) where T <: TransportMode
    # if bump map, update si
    if !(m.bump_map isa Nothing)
        bump!(m, si)
    end
    
    d = m.Kd(si)
    s = m.Ks(si)
    roughu = clamp(m.u_roughness(si), 0, 1)
    roughv = clamp(m.v_roughness(si), 0, 1)
    # TODO implement black body check

    if m.remap_roughness
        roughu = roughness_to_alpha(roughu)
        roughv = roughness_to_alpha(roughv)
    end
    distrib = TrowbridgeReitzDistribution(roughu, roughv)
    si.bsdf = BSDF(si, 1.0, (FresnelBlend(d, s, distrib),))
end

function albedo(m::Substrate, si::SurfaceInteraction)::Spectrum
    d = m.Kd(si)
    s = m.Ks(si)
    return d + s
end
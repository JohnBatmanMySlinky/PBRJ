# PBR 9.2.1 Matte Material
struct Uber{
        KD <: AbstractTexture{Spectrum},
        KS <: AbstractTexture{Spectrum},
        KR <: AbstractTexture{Spectrum},
        KT <: AbstractTexture{Spectrum},
        R <: AbstractTexture{Float64},
        UR <: Maybe{AbstractTexture{Float64}},
        VR <: Maybe{AbstractTexture{Float64}},
        E <: AbstractTexture{Float64},
        O <: AbstractTexture{Spectrum},
        BM <: Maybe{AbstractTexture{Float64}}
    } <: Material
    Kd::KD
    Ks::KS
    Kr::KR
    Kt::KT
    roughness::R
    uroughness::UR
    vroughness::VR
    eta::E
    opacity::O
    bump_map::BM
    remap_roughness::Bool

    function Uber(
        Kd::KD=ConstantTexture(spectrum_from_float(0.25)),
        Ks::KS=ConstantTexture(spectrum_from_float(0.25)),
        Kr::KR=ConstantTexture(spectrum_from_float(0.0)),
        Kt::KT=ConstantTexture(spectrum_from_float(0.0)),
        roughness::R=ConstantTexture(1.0),
        uroughness::UR=nothing,
        vroughness::VR=nothing,
        eta::E=ConstantTexture(1.5),
        opacity::O=ConstantTexture(spectrum_from_float(0.0)),
        bump_map::BM=nothing,
        remap_roughness::Bool=true
    )::Uber where {
        KD <: AbstractTexture{Spectrum},
        KS <: AbstractTexture{Spectrum},
        KR <: AbstractTexture{Spectrum},
        KT <: AbstractTexture{Spectrum},
        R <: AbstractTexture{Float64},
        UR <: Maybe{AbstractTexture{Float64}},
        VR <: Maybe{AbstractTexture{Float64}},
        E <: AbstractTexture{Float64},
        O <: AbstractTexture{Spectrum},
        BM <: Maybe{AbstractTexture{Float64}}
    }
        return new{KD, KS, KR, KT, R, UR, VR, E, O, BM}(
            Kd, Ks, Kr, Kt, 
            roughness, uroughness, vroughness, 
            eta, opacity, bump_map, remap_roughness
        )
    end
end


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
    name::String

    function Uber(
        name::String,
        Kd::KD=ConstantTexture(spectrum_from_float(0.25)),
        Ks::KS=ConstantTexture(spectrum_from_float(0.25)),
        Kr::KR=ConstantTexture(spectrum_from_float(0.0)),
        Kt::KT=ConstantTexture(spectrum_from_float(0.0)),
        roughness::R=ConstantTexture(1.0),
        uroughness::UR=nothing,
        vroughness::VR=nothing,
        eta::E=ConstantTexture(1.5),
        opacity::O=ConstantTexture(spectrum_from_float(1.0)),
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
            eta, opacity, bump_map, 
            remap_roughness, name
        )
    end
end


# Equivalent to PBR's ComputeScatteringFunction
function (u::Uber)(si::SurfaceInteraction, allow_multiple_lobes::Bool, mode::Type{T}) where T <: TransportMode
    # if bump map, update si
    if !(u.bump_map isa Nothing)
        bump!(u, si)
    end

    e = u.eta(si)
    op = clamp.(u.opacity(si), 0.0, 1.0)
    t = clamp.(spectrum_from_float(1.0) - op, 0.0, 1.0)
    if !is_black(t)
        si.bsdf = BSDF(si)
        add!(si.bsdf, SpecularTransmission(t, 1.0, 1.0, mode))
    else
        si.bsdf = BSDF(si, e)
    end

    kd = op * clamp.(u.Kd(si), 0.0, 1.0)
    if !is_black(kd)
        add!(si.bsdf, LambertianReflection(kd))
    end

    ks = op * clamp.(u.Ks(si), 0.0, 1.0)
    if !is_black(ks)
        fresnel = FresnelDielectric(1.0, e)
        if !(u.uroughness isa Nothing)
            urough = u.uroughness(si)
        else
            urough = u.roughness(si)
        end
        if !(u.vroughness isa Nothing)
            vrough = u.vroughness(si)
        else
            vrough = urough
        end
        if u.remap_roughness
            urough = roughness_to_alpha(urough)
            vrough = roughness_to_alpha(vrough)
        end
        distrib = TrowbridgeReitzDistribution(urough, vrough)
        add!(si.bsdf, MicrofacetReflection(ks, distrib, fresnel))
    end

    kr = op * clamp.(u.Kr(si), 0.0, 1.0)
    if !is_black(kr)
        fresnel = FresnelDielectric(1.0, e)
        add!(si.bsdf, SpecularReflection(kr, fresnel))
    end

    kt = op * clamp.(u.Kt(si), 0.0, 1.0)
    if !is_black(kt)
        add!(si.bsdf, SpecularTransmission(kt, 1.0, e, mode))
    end
end


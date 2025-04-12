struct Glass{
    KR <: AbstractTexture{Spectrum},
    KT <: AbstractTexture{Spectrum},
    U <: AbstractTexture{Float64},
    V <: AbstractTexture{Float64},
    I <: AbstractTexture{Float64},
    BM <: Maybe{AbstractTexture{Float64}}
} <: Material
    Kr::KR
    Kt::KT
    u_roughness::U
    v_roughness::V
    idx::I
    bump_map::BM
    remap_roughness::Bool

    function Glass(
        Kr::KR=ConstantTexture(spectrum_from_float(1.0)),
        Kt::KT=ConstantTexture(spectrum_from_float(1.0)),
        u_roughness::U=ConstantTexture(0.0),
        v_roughness::V=ConstantTexture(0.0),
        idx::I=ConstantTexture(1.5),
        bump_map::BM=nothing,
        remap_roughness::Bool=true
    )::Glass where {
        KR <: AbstractTexture{Spectrum},
        KT <: AbstractTexture{Spectrum},
        U <: AbstractTexture{Float64},
        V <: AbstractTexture{Float64},
        I <: AbstractTexture{Float64},
        BM <: Maybe{AbstractTexture{Float64}}
    }
        return new{KR, KT, U, V, I, BM}(Kr, Kt, u_roughness, v_roughness, idx, bump_map, remap_roughness)
    end
end

# Equivalent to PBR's ComputeScatteringFunction
function (g::Glass)(si::SurfaceInteraction, allow_multiple_lobes::Bool, mode::Type{T}) where T <: TransportMode
    # if bump map, update si
    if !(g.bump_map isa Nothing)
        bump!(g, si)
    end
    
    eta::Float64 = g.idx(si)
    urough::Float64 = g.u_roughness(si)
    vrough::Float64 = g.v_roughness(si)
    KR::Spectrum = g.Kr(si)
    KT::Spectrum = g.Kt(si)

    # initialize _bsdf_ for smooth or rough dielectric
    si.bsdf = BSDF(si, eta)

    # SKIP IS BLACK TEST

    is_specular = (urough == 0.0) && (vrough == 0.0)
    if is_specular && allow_multiple_lobes
        add!(si.bsdf, FresnelSpecular(KR, KT, 1.0, eta, mode))
    else
        if g.remap_roughness == true
            urough = roughness_to_alpha(urough)
            vrough = roughness_to_alpha(vrough)
        end

        distrib = is_specular ? Nothing : TrowbridgeReitzDistribution(urough, vrough)
        
        # skipping R black check
        fresnel = FresnelDielectric(1.0, eta)
        if is_specular == true
            add!(si.bsdf, SpecularReflection(KR, fresnel))
        else
            add!(si.bsdf, MicrofacetReflection(KR, distrib, fresnel))
        end

        # skipping T black check
        if is_specular == true
            add!(si.bsdf, SpecularTransmission(KT, 1.0, eta, mode))
        else
            add!(si.bsdf, MicrofacetTransmission(KT, distrib, 1.0, eta, mode))
        end
    end
end


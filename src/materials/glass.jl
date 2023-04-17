struct Glass <: Material
    Kr::Texture
    Kt::Texture
    u_roughness::Texture
    v_roughness::Texture
    idx::Texture
    bump_map::Maybe{Texture}
    remap_roughness::Bool

    function Glass(
        Kr::Spectrum=ConstantTexture(Pnt3(1.0)),
        Kt::Spectrum=ConstantTexture(Pnt3(1.0)),
        u_roughness::Spectrum=ConstantTexture(Pnt3(0.0)),
        v_roughness::Spectrum=ConstantTexture(Pnt3(0.0)),
        eta::Spectrum=ConstantTexture(Pnt3(1.5)),
        bump_map::{MaybeTexture}=Nothing,
        remap_roughness::Bool=True
    )::Glass
        return new(Kr, Kt, u_roughness, v_roughness, eta, bump_map, remap_roughness)
    end
end

# Equivalent to PBR's ComputeScatteringFunction
function (g::Glass)(si::SurfaceInteraction, allow_multiple_lobes::Bool, mode::Type{T}) where T <: TransportMode
    # if bump map, update si
    if !(p.bump_map isa Nothing)
        bump!(p, si)
    end
    
    eta::Float64 = mean(g.idx(si))
    urough::Float64 = mean(g.u_roughness(si))
    vrough::Float64 = mean(g.v_roughness(si))
    KR::Spectrum = clamp!.(g.Kr(si), 0.0, 1.0)
    KT::Spectrum = clamp!.(g.Kt(si), 0.0, 1.0)

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
            add(si.bsdf, MicrofacetReflection(KR, distrib, fresnel))
        end

        # skipping T black check
        if is_specular == true
            add!(si.bsdf, SpecularTransmission(KT, 1.0, eta, mode))
        else
            add!(si.bsdf, MicrofacetTransmission(KT, distrib, 1.0, eta, mode))
        end
    end
end


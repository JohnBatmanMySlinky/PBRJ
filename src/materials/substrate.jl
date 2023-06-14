struct Substrate <: Material
    Kd::Texture
    Ks::Texture
    uroughness::Texture
    vroughness::Texture
    remap_roughness::Bool
    bump_map::Maybe{Texture}
end

# Equivalent to PBR's ComputeScatteringFunction
function (m::Substrate)(si::SurfaceInteraction, ::Bool, ::Type{T}) where T <: TransportMode
    # if bump map, update si
    if !(m.bump_map isa Nothing)
        bump!(m, si)
    end
    
    si.bsdf = BSDF(si)
    d = spectrum_from_float(clamp.(m.Kd(si),0,1)...)
    s = spectrum_from_float(clamp.(m.Ks(si),0,1)...)
    roughu = mean(clamp.(m.uroughness(si),0,1))
    roughv = mean(clamp.(m.vroughness(si),0,1))
    # TODO implement black body check

    if m.remap_roughness
        roughu = roughness_to_alpha(roughu)
        roughv = roughness_to_alpha(roughv)
    end
    distrib = TrowbridgeReitzDistribution(roughu, roughv)
    add!(si.bsdf, FresnelBlend(d, s, distrib))
end
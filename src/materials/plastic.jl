# PBR 9.2.2 Plastic Material
struct Plastic <: Material
    Kd::Texture
    Ks::Texture
    roughness::Texture
    bump_map::Maybe{Texture}
    remap_roughness::Bool
end


# Equivalent to PBR's ComputeScatteringFunction
function (p::Plastic)(si::SurfaceInteraction, ::Bool, ::Type{T}) where T <: TransportMode
    # if bump map, update si
    if !(p.bump_map isa Nothing)
        bump!(p, si)
    end
    
    # initialize diffuse component of plastic material
    si.bsdf = BSDF(si)
    kd = spectrum_from_float(clamp.(p.Kd(si),0,1)...)
    add!(si.bsdf, LambertianReflection(kd))

    # initialize specular component of plastic material
    ks = spectrum_from_float(clamp.(p.Ks(si),0,1)...)
    fresnel = FresnelDielectric(1.0, 1.5)
    rough = mean(p.roughness(si))
    if p.remap_roughness
        rough = roughness_to_alpha(rough)
    end
    distrib = TrowbridgeReitzDistribution(rough, rough)
    add!(si.bsdf, MicrofacetReflection(ks, distrib, fresnel))
end


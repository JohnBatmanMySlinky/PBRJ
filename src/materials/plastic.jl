# PBR 9.2.2 Plastic Material
struct Plastic <: Material
    Kd::Texture{Spectrum}
    Ks::Texture{Spectrum}
    roughness::Maybe{Texture{Float64}}
    u_roughness::Maybe{Texture{Float64}}
    v_roughness::Maybe{Texture{Float64}}
    bump_map::Maybe{Texture{Float64}}
    remap_roughness::Bool

    function Plastic(
        Kd::Texture{Spectrum}=ConstantTexture(spectrum_from_float(0.25)),
        Ks::Texture{Spectrum}=ConstantTexture(spectrum_from_float(0.25)),
        roughness::Maybe{Texture{Float64}}=nothing,
        u_roughness::Maybe{Texture{Float64}}=nothing,
        v_roughness::Maybe{Texture{Float64}}=nothing,
        bump_map::Maybe{Texture{Float64}}=nothing,
        remap_roughness::Bool=true
    )
        if !(roughness isa Nothing)
            @assert (u_roughness isa Nothing) & (v_roughness isa Nothing)
        else
            @assert !(u_roughness isa Nothing) & !(v_roughness isa Nothing)
        end
        
        if roughness isa Nothing
            roughness = ConstantTexture(0.0)
        end
        if u_roughness isa Nothing
            u_roughness = ConstantTexture(0.0)
        end
        if v_roughness isa Nothing
            v_roughness = ConstantTexture(0.0)
        end
        
        return new(Kd, Ks, roughness, u_roughness, v_roughness, bump_map, remap_roughness)
    end
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


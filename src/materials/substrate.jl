struct Substrate <: Material
    Kd::Texture{Spectrum}
    Ks::Texture{Spectrum}
    u_roughness::Maybe{Texture{Float64}}
    v_roughness::Maybe{Texture{Float64}}
    bump_map::Maybe{Texture{Float64}}
    remap_roughness::Bool

    function Substrate(
        Kd::Texture{Spectrum}=ConstantTexture(spectrum_from_float(0.5)),
        Ks::Texture{Spectrum}=ConstantTexture(spectrum_from_float(0.5)),
        u_roughness::Maybe{Texture{Float64}}=nothing,
        v_roughness::Maybe{Texture{Float64}}=nothing,
        bump_map::Maybe{Texture{Float64}}=nothing,
        remap_roughness::Bool=true
    )
        if u_roughness isa Nothing
            u_roughness = ConstantTexture(0.1)
        end
        if v_roughness isa Nothing
            v_roughness = ConstantTexture(0.1)
        end
        
        return new(Kd, Ks, u_roughness, v_roughness, bump_map, remap_roughness)
    end
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
    roughu = clamp(m.u_roughness(si), 0, 1)
    roughv = clamp(m.v_roughness(si), 0, 1)
    # TODO implement black body check

    if m.remap_roughness
        roughu = roughness_to_alpha(roughu)
        roughv = roughness_to_alpha(roughv)
    end
    distrib = TrowbridgeReitzDistribution(roughu, roughv)
    add!(si.bsdf, FresnelBlend(d, s, distrib))
end
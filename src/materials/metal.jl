struct Metal <: Material
    eta::Texture
    k::Texture
    roughness::Texture
    u_roughness::Maybe{Texture}
    v_roughness::Maybe{Texture}
    bump_map::Maybe{Texture}
    remap_roughness::Bool

    function Metal(
        eta::Texture=ConstantTexture(spectrum_from_sampled(CopperWavelengths, CopperN, CopperSamples)),
        k::Texture=ConstantTexture(spectrum_from_sampled(CopperWavelengths, CopperK, CopperSamples)),
        roughness::Texture=ConstantTexture(spectrum_from_float(.01)),
        u_roughness::Maybe{Texture}=nothing,
        v_roughness::Maybe{Texture}=nothing,
        bump_map::Maybe{Texture}=nothing,
        remap_roughness::Bool=true
    )::Metal
        return new(eta, k, roughness, u_roughness, v_roughness, bump_map, remap_roughness)
    end
end

const CopperSamples = 56
const CopperWavelengths = Float64[
    298.7570554, 302.4004341, 306.1337728, 309.960445,  313.8839949,
    317.9081487, 322.036826,  326.2741526, 330.6244747, 335.092373,
    339.6826795, 344.4004944, 349.2512056, 354.2405086, 359.374429,
    364.6593471, 370.1020239, 375.7096303, 381.4897785, 387.4505563,
    393.6005651, 399.9489613, 406.5055016, 413.2805933, 420.2853492,
    427.5316483, 435.0322035, 442.8006357, 450.8515564, 459.2006593,
    467.8648226, 476.8622231, 486.2124627, 495.936712,  506.0578694,
    516.6007417, 527.5922468, 539.0616435, 551.0407911, 563.5644455,
    576.6705953, 590.4008476, 604.8008683, 619.92089,   635.8162974,
    652.5483053, 670.1847459, 688.8009889, 708.4810171, 729.3186941,
    751.4192606, 774.9011125, 799.8979226, 826.5611867, 855.0632966,
    885.6012714]
const CopperN = Float64[
    1.400313, 1.38,  1.358438, 1.34,  1.329063, 1.325, 1.3325,   1.34,
    1.334375, 1.325, 1.317812, 1.31,  1.300313, 1.29,  1.281563, 1.27,
    1.249062, 1.225, 1.2,      1.18,  1.174375, 1.175, 1.1775,   1.18,
    1.178125, 1.175, 1.172812, 1.17,  1.165312, 1.16,  1.155312, 1.15,
    1.142812, 1.135, 1.131562, 1.12,  1.092437, 1.04,  0.950375, 0.826,
    0.645875, 0.468, 0.35125,  0.272, 0.230813, 0.214, 0.20925,  0.213,
    0.21625,  0.223, 0.2365,   0.25,  0.254188, 0.26,  0.28,     0.3]
const CopperK = Float64[
    1.662125, 1.687, 1.703313, 1.72,  1.744563, 1.77,  1.791625, 1.81,
    1.822125, 1.834, 1.85175,  1.872, 1.89425,  1.916, 1.931688, 1.95,
    1.972438, 2.015, 2.121562, 2.21,  2.177188, 2.13,  2.160063, 2.21,
    2.249938, 2.289, 2.326,    2.362, 2.397625, 2.433, 2.469187, 2.504,
    2.535875, 2.564, 2.589625, 2.605, 2.595562, 2.583, 2.5765,   2.599,
    2.678062, 2.809, 3.01075,  3.24,  3.458187, 3.67,  3.863125, 4.05,
    4.239563, 4.43,  4.619563, 4.817, 5.034125, 5.26,  5.485625, 5.717]


# Equivalent to PBR's ComputeScatteringFunction
function (m::Metal)(si::SurfaceInteraction, ::Bool, ::Type{T}) where T <: TransportMode
    # if bump map, update si
    if !(m.bump_map isa Nothing)
        bump!(m, si)
    end

    si.bsdf = BSDF(si)

    # JOHN TODO fair amount of kludging in here
    u_rough::Float64 = (m.u_roughness isa Nothing) ? y(m.roughness(si)) : y(m.u_roughness(si))
    v_rough::Float64 = (m.v_roughness isa Nothing) ? y(m.roughness(si)) : y(m.v_roughness(si))
    if m.remap_roughness
        u_rough = roughness_to_alpha(u_rough)
        v_rough = roughness_to_alpha(v_rough)
    end
    fresnel = FresnelConductor(spectrum_from_float(1.0), m.eta(si), m.k(si))
    distrib = TrowbridgeReitzDistribution(u_rough, v_rough)
    add!(si.bsdf, MicrofacetReflection(spectrum_from_float(1.0), distrib, fresnel))
end
# PBR 9.2.2 Plastic Material
struct Plastic{
    KD <: AbstractTexture{Spectrum},
    KS <: AbstractTexture{Spectrum},
    R <: Maybe{AbstractTexture{Float64}},
    U <: Maybe{AbstractTexture{Float64}},
    V <: Maybe{AbstractTexture{Float64}},
    BM <: Maybe{AbstractTexture{Float64}}
} <: Material
    Kd::KD
    Ks::KS
    roughness::R
    u_roughness::U
    v_roughness::V
    bump_map::BM
    remap_roughness::Bool
    hash::UInt32

    function Plastic(
        name::String,
        Kd::KD=ConstantTexture(spectrum_from_float(0.25)),
        Ks::KS=ConstantTexture(spectrum_from_float(0.25)),
        roughness::R=ConstantTexture(0.01),
        u_roughness::U=nothing,
        v_roughness::V=nothing,
        bump_map::BM=nothing,
        remap_roughness::Bool=true
    )::Plastic where {
        KD <: AbstractTexture{Spectrum},
        KS <: AbstractTexture{Spectrum},
        R <: Maybe{AbstractTexture{Float64}},
        U <: Maybe{AbstractTexture{Float64}},
        V <: Maybe{AbstractTexture{Float64}},
        BM <: Maybe{AbstractTexture{Float64}}
    }
        if !(roughness isa Nothing)
            @assert (u_roughness isa Nothing) & (v_roughness isa Nothing)
        else
            @assert !(u_roughness isa Nothing) & !(v_roughness isa Nothing)
        end
        
        return new{KD, KS, R, U, V, BM}(Kd, Ks, roughness, u_roughness, v_roughness, bump_map, remap_roughness, crc32c(name))
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
    kd = p.Kd(si)
    add!(si.bsdf, LambertianReflection(kd))

    # initialize specular component of plastic material
    ks = p.Ks(si)
    fresnel = FresnelDielectric(1.0, 1.5)
    rough = mean(p.roughness(si))
    if p.remap_roughness
        rough = roughness_to_alpha(rough)
    end
    distrib = TrowbridgeReitzDistribution(rough, rough)
    add!(si.bsdf, MicrofacetReflection(ks, distrib, fresnel))
end

function albedo(m::Plastic, si::SurfaceInteraction)::Spectrum
    kd = m.Kd(si)
    ks = m.Ks(si)
    
    # Fresnel reflectance at normal incidence for dielectric (n1=1.0, n2=1.5)
    eta = 1.5
    F0 = ((eta - 1.0) / (eta + 1.0))^2  # = 0.04
    
    # Energy not reflected goes into diffuse layer
    return kd .* (1.0 - F0) .+ ks .* F0
end
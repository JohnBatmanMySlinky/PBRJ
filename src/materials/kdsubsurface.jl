struct KdSubSurface{
    KD <: AbstractTexture{Spectrum},
    KR <: AbstractTexture{Spectrum},
    KT <: AbstractTexture{Spectrum},
    MFP <: AbstractTexture{Spectrum},
    U <: AbstractTexture{Float64},
    V <: AbstractTexture{Float64},
    BM <: Maybe{AbstractTexture{Float64}}
} <: Material
    Kd::KD
    Kr::KR
    Kt::KT
    Mfp::MFP
    u_roughness::U
    v_roughness::V
    scale::Float64
    eta::Float64
    bump_map::BM
    name::String
    table::BSSRDFTable
    remap_roughness::Bool

    function KdSubSurface(
        name::String,
        Kd::KD=ConstantTexture(spectrum_from_float(0.5, 0.5, 0.5)),
        Kr::KR=ConstantTexture(spectrum_from_float(1.0)),
        Kt::KT=ConstantTexture(spectrum_from_float(1.0)),
        Mfp::MFP=ConstantTexture(spectrum_from_float(1.0)),
        u_roughness::U=ConstantTexture(0.0),
        v_roughness::V=ConstantTexture(0.0),
        scale::Float64=1.0,
        eta::Float64=1.33,
        g::Float64=0.0,
        bump_map::BM=nothing,
        remap_roughness::Bool=true
    )::KdSubSurface where {
        KD <: AbstractTexture{Spectrum},
        KR <: AbstractTexture{Spectrum},
        KT <: AbstractTexture{Spectrum},
        MFP <: AbstractTexture{Spectrum},
        U <: AbstractTexture{Float64},
        V <: AbstractTexture{Float64},
        BM <: Maybe{AbstractTexture{Float64}}
    }
        table = BSSRDFTable(g, eta)
        return new{KD, KR, KT, MFP, U, V, BM}(Kd, Kr, Kt, Mfp, u_roughness, v_roughness, scale, eta, bump_map, name, table, remap_roughness)
    end
end

struct SeperableBSSRDF
    po::SurfaceInteraction
    eta::Float64
    ns::Nml3
    ss::Vec3
    ts::Vec3
    material::Material
    mode::Type{T} where T <: TransportMode

    function SeperableBSSRDF(po::SurfaceInteraction, material::Material, mode::Type{T}) where T <: TransportMode
        ns = po.shading.n
        ss = normalize(po.shading.dpdu)
        ts = cross(ns, ss)
        return new(po, material.eta, ns, ss, ts, material, mode)
    end
end

struct TabulatedBSSRDF <: AbstractBSSRDF
    seperable_bssrdf::SeperableBSSRDF
    sigma_t::Spectrum
    rho::Spectrum

    function TabulatedBSSRDF(po::SurfaceInteraction, ss::KdSubSurface, mode::Type{T}, sig_a::Spectrum, sig_s::Spectrum) where T <: TransportMode
        sigma_t = sig_a + sig_s
        rho = zeros(Float64, nSpectralSamples)
        for c in 0:(nSpectralSamples - 1)
            rho[c + 1] = sigma_t[c + 1] != 0.0 ? (sig_s[c + 1] / sigma_t[c + 1]) : 0.0
        end
        return new(
            SeperableBSSRDF(po, ss, mode),
            sigma_t,
            Spectrum(rho)
        )
    end
end

function (ss::KdSubSurface)(si::SurfaceInteraction, allow_multiple_lobes::Bool, mode::Type{T}) where T <: TransportMode
    # if bump map, update si
    if !(ss.bump_map isa Nothing)
        @info "BUMP BUMP BUMP"
        @info "Surface Interaction Pre Bump: $si"
        bump!(ss, si)
        @info "Surface Interaction Post Bump: $si"
    end

    # Initialize _bsdf_ for smooth or rough dielectric
    si.bsdf = BSDF(si, ss.eta)

    RR = clamp.(ss.Kr(si), 0.0, 1.0)
    TT = clamp.(ss.Kt(si), 0.0, 1.0)
    u_rough = clamp.(ss.u_roughness(si), 0.0, 1.0)
    v_rough = clamp.(ss.v_roughness(si), 0.0, 1.0)

    if is_black(RR) && is_black(TT)
        #JOHN HACK Hmmmmmm is this going to flow thru OK?
        return
    end

    is_specular = (u_rough == 0.0) && (v_rough == 0.0)
    if is_specular && allow_multiple_lobes
        add!(si.bsdf, FresnelSpecular(RR, TT, 1.0, eta, mode))
    else
        if ss.remap_roughness
            u_rough = roughness_to_alpha(u_rough)
            v_rough = roughness_to_alpha(v_rough)
        end

        if !is_black(RR)
            fresnel = FresnelDielectric(1.0, ss.eta)
            if is_specular
                add!(si.bsdf, SpecularReflection(RR, fresnel))
            else
                distrib = TrowbridgeReitzDistribution(u_rough, v_rough)
                add!(si.bsdf, MicrofacetReflection(RR, distrib, fresnel))
            end
        end

        if !is_black(TT)
            if is_specular
                add!(si.bsdf, SpecularTransmission(TT, 1.0, ss.eta, mode))
            else
                distrib = TrowbridgeReitzDistribution(u_rough, v_rough)
                add!(si.bsdf, MicrofacetTransmission(TT, distrib, 1.0, ss.eta, mode))
            end
        end
    end

    mfree = ss.scale * clamp.(ss.Mfp(si), 0.0, 1.0)
    kd = clamp.(ss.Kd(si), 0.0, 1.0)
    sig_a, sig_s = subsurface_from_diffuse(ss.table, kd, mfree)
    si.bssrdf = TabulatedBSSRDF(si, ss, mode, sig_a, sig_s)
end
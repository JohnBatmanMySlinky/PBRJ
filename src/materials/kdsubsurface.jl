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

struct SubSurface{
    KR <: AbstractTexture{Spectrum},
    KT <: AbstractTexture{Spectrum},
    SA <: AbstractTexture{Spectrum},
    SS <: AbstractTexture{Spectrum},
    U <: AbstractTexture{Float64},
    V <: AbstractTexture{Float64},
    BM <: Maybe{AbstractTexture{Float64}}
} <: Material
    Kr::KR
    Kt::KT
    sigma_a::SA
    sigma_s::SS
    u_roughness::U
    v_roughness::V
    scale::Float64
    eta::Float64
    bump_map::BM
    name::String
    table::BSSRDFTable
    remap_roughness::Bool

    function SubSurface(
        name::String,
        Kr::KR=ConstantTexture(spectrum_from_float(1.0)),
        Kt::KT=ConstantTexture(spectrum_from_float(1.0)),
        sigma_a::SA=ConstantTexture(spectrum_from_float(.0011, .0024, .014)),
        sigma_s::SS=ConstantTexture(spectrum_from_float(2.55, 3.21, 3.77)),
        u_roughness::U=ConstantTexture(0.0),
        v_roughness::V=ConstantTexture(0.0),
        scale::Float64=1.0,
        eta::Float64=1.33,
        g::Float64=0.0,
        bump_map::BM=nothing,
        remap_roughness::Bool=true
    )::SubSurface where {
        KR <: AbstractTexture{Spectrum},
        KT <: AbstractTexture{Spectrum},
        SA <: AbstractTexture{Spectrum},
        SS <: AbstractTexture{Spectrum},
        U <: AbstractTexture{Float64},
        V <: AbstractTexture{Float64},
        BM <: Maybe{AbstractTexture{Float64}}
    }
        table = BSSRDFTable(g, eta)
        return new{KR, KT, SA, SS, U, V, BM}(Kr, Kt, sigma_a, sigma_s, u_roughness, v_roughness, scale, eta, bump_map, name, table, remap_roughness)
    end
end


struct SeperableBSSRDF{M}
    po::SurfaceInteraction
    eta::Float64
    ns::Nml3
    ss::Vec3
    ts::Vec3
    material_name::String
    mode::Type{M}

    function SeperableBSSRDF(po::SurfaceInteraction, material::Material, mode::Type{M}) where {M}
        ns = po.shading.n
        ss = normalize(po.shading.dpdu)
        ts = cross(ns, ss)
        return new{M}(po, material.eta, ns, ss, ts, material.name, mode)
    end
end

struct TabulatedBSSRDF{M} <: AbstractBSSRDF
    seperable_bssrdf::SeperableBSSRDF{M}
    sigma_t::Spectrum
    rho::Spectrum

    function TabulatedBSSRDF(po::SurfaceInteraction, ss::Union{KdSubSurface, SubSurface}, mode::Type{M}, sig_a::Spectrum, sig_s::Spectrum) where {M}
        sigma_t = sig_a + sig_s
        @info "TabulatedBSSRDF::sigma_a = $sig_a, sigma_s = $sig_s, sigma_t = $sigma_t"
        rho = zeros(Float64, nSpectralSamples)
        for c in 0:(nSpectralSamples - 1)
            rho[c + 1] = sigma_t[c + 1] != 0.0 ? (sig_s[c + 1] / sigma_t[c + 1]) : 0.0
        end
        @info "TabulatedBSSRDF::rho_raw = $rho, rho_spectrum = $(Spectrum(rho))"
        return new{M}(
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

    RR = ss.Kr(si)
    TT = ss.Kt(si)
    u_rough = ss.u_roughness(si)
    v_rough = ss.v_roughness(si)

    if is_black(RR) && is_black(TT)
        #JOHN HACK Hmmmmmm is this going to flow thru OK?
        si.bsdf = BSDF(si, ss.eta, ())
        return
    end

    is_specular = (u_rough == 0.0) && (v_rough == 0.0)
    if is_specular && allow_multiple_lobes
        si.bsdf = BSDF(si, ss.eta, (FresnelSpecular(RR, TT, 1.0, eta, mode),))
    else
        if ss.remap_roughness
            u_rough = roughness_to_alpha(u_rough)
            v_rough = roughness_to_alpha(v_rough)
        end
        bxdfs = AbstractBxDF[]
        if !is_black(RR)
            fresnel = FresnelDielectric(1.0, ss.eta)
            if is_specular
                push!(bxdfs, SpecularReflection(RR, fresnel))
            else
                distrib = MicrofacetDistributionImpl(u_rough, v_rough)
                push!(bxdfs, MicrofacetReflection(RR, distrib, fresnel))
            end
        end
        if !is_black(TT)
            if is_specular
                push!(bxdfs, SpecularTransmission(TT, 1.0, ss.eta, mode))
            else
                distrib = MicrofacetDistributionImpl(u_rough, v_rough)
                push!(bxdfs, MicrofacetTransmission(TT, distrib, 1.0, ss.eta, mode))
            end
        end
        si.bsdf = BSDF(si, ss.eta, tuple(bxdfs...))
    end

    mfree = ss.scale * ss.Mfp(si)
    kd = ss.Kd(si)
    sig_a, sig_s = subsurface_from_diffuse(ss.table, kd, mfree)
    si.bssrdf = TabulatedBSSRDF(si, ss, mode, sig_a, sig_s)
end

function (ss::SubSurface)(si::SurfaceInteraction, allow_multiple_lobes::Bool, mode::Type{T}) where T <: TransportMode
    # if bump map, update si
    if !(ss.bump_map isa Nothing)
        bump!(ss, si)
    end

    RR = ss.Kr(si)
    TT = ss.Kt(si)
    u_rough = ss.u_roughness(si)
    v_rough = ss.v_roughness(si)

    if is_black(RR) && is_black(TT)
        #JOHN HACK Hmmmmmm is this going to flow thru OK?
        si.bsdf = BSDF(si, ss.eta, ())
        return
    end

    is_specular = (u_rough == 0.0) && (v_rough == 0.0)
    if is_specular && allow_multiple_lobes
        si.bsdf = BSDF(si, ss.eta, (FresnelSpecular(RR, TT, 1.0, ss.eta, mode),))
    else
        if ss.remap_roughness
            u_rough = roughness_to_alpha(u_rough)
            v_rough = roughness_to_alpha(v_rough)
        end
        bxdfs = AbstractBxDF[]
        if !is_black(RR)
            fresnel = FresnelDielectric(1.0, ss.eta)
            if is_specular
                push!(bxdfs, SpecularReflection(RR, fresnel))
            else
                distrib = MicrofacetDistributionImpl(u_rough, v_rough)
                push!(bxdfs, MicrofacetReflection(RR, distrib, fresnel))
            end
        end
        if !is_black(TT)
            if is_specular
                push!(bxdfs, SpecularTransmission(TT, 1.0, ss.eta, mode))
            else
                distrib = MicrofacetDistributionImpl(u_rough, v_rough)
                push!(bxdfs, MicrofacetTransmission(TT, distrib, 1.0, ss.eta, mode))
            end
        end
        si.bsdf = BSDF(si, ss.eta, tuple(bxdfs...))
    end

    sig_a = ss.scale * ss.sigma_a(si)
    sig_s = ss.scale * ss.sigma_s(si)
    si.bssrdf = TabulatedBSSRDF(si, ss, mode, sig_a, sig_s)
end

function albedo(m::KdSubSurface, si::SurfaceInteraction)::Spectrum
    # Surface reflection component
    RR = m.Kr(si)
    
    # Fresnel reflectance at normal incidence for dielectric
    F0 = ((m.eta - 1.0) / (m.eta + 1.0))^2
    
    # Diffuse subsurface component
    kd = m.Kd(si)
    
    # Combine: surface reflection + transmitted light that scatters back out
    # Energy that transmits into the material: (1 - F0)
    # Of that, kd determines how much scatters back (approximate)
    return RR .* F0 .+ kd .* (1.0 - F0)
end

function albedo(m::SubSurface, si::SurfaceInteraction)::Spectrum
    # Surface reflection component
    RR = m.Kr(si)
    
    # Fresnel reflectance at normal incidence
    F0 = ((m.eta - 1.0) / (m.eta + 1.0))^2
    
    # Single-scattering albedo from absorption and scattering coefficients
    sig_a = m.scale * m.sigma_a(si)
    sig_s = m.scale * m.sigma_s(si)
    sigma_t = sig_a + sig_s
    
    # Single-scattering albedo: rho = sigma_s / sigma_t
    rho = similar(sig_s)
    for c in 1:length(sigma_t)
        rho[c] = sigma_t[c] != 0.0 ? (sig_s[c] / sigma_t[c]) : 0.0
    end
    
    # Combine surface and subsurface components
    return RR .* F0 .+ rho .* (1.0 - F0)
end
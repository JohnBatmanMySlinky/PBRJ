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
    name::String

    function Glass(
        name::String,
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
        return new{KR, KT, U, V, I, BM}(Kr, Kt, u_roughness, v_roughness, idx, bump_map, remap_roughness, name)
    end
end

# Equivalent to PBR's ComputeScatteringFunction
function (g::Glass)(si::SurfaceInteraction, allow_multiple_lobes::Bool, mode::Type{T}) where T <: TransportMode
    # if bump map, update si
    if !(g.bump_map isa Nothing)
        @info "BUMP BUMP BUMP"
        @info "SI PRE :\n\tp: $(si.core.p)\n\t:t: $(si.core.t)\n\two: $(si.core.wo)\n\tn: $(si.core.n)\n\tuv: $(si.uv)\n\tdpdu: $(si.dpdu)\n\tdpdv: $(si.dpdv)\n\tdndu: $(si.dndu)\n\tdndv: $(si.dndv)\n\tsn: $(si.shading.n)\n\tsdpdu: $(si.shading.dpdu)\n\tsdpdv: $(si.shading.dpdv)\n\tdudx: $(si.dudx)\n\tdudy: $(si.dudy)\n\tdvdx: $(si.dvdx)\n\tdvdy: $(si.dvdy)\n\t:dpdx: $(si.dpdx)\n\t:dpdy: $(si.dpdy)"
        bump!(g, si)
        @info "SI POST:\n\tp: $(si.core.p)\n\t:t: $(si.core.t)\n\two: $(si.core.wo)\n\tn: $(si.core.n)\n\tuv: $(si.uv)\n\tdpdu: $(si.dpdu)\n\tdpdv: $(si.dpdv)\n\tdndu: $(si.dndu)\n\tdndv: $(si.dndv)\n\tsn: $(si.shading.n)\n\tsdpdu: $(si.shading.dpdu)\n\tsdpdv: $(si.shading.dpdv)\n\tdudx: $(si.dudx)\n\tdudy: $(si.dudy)\n\tdvdx: $(si.dvdx)\n\tdvdy: $(si.dvdy)\n\t:dpdx: $(si.dpdx)\n\t:dpdy: $(si.dpdy)"
    end
    
    eta::Float64 = g.idx(si)
    urough::Float64 = g.u_roughness(si)
    vrough::Float64 = g.v_roughness(si)
    KR::Spectrum = g.Kr(si)
    KT::Spectrum = g.Kt(si)

    # SKIP IS BLACK TEST

    is_specular = (urough == 0.0) && (vrough == 0.0)
    if is_specular && allow_multiple_lobes
        si.bsdf = BSDF(si, eta, (FresnelSpecular(KR, KT, 1.0, eta, mode),))
    elseif is_specular
        # skipping R/T black check
        fresnel = FresnelDielectric(1.0, eta)
        si.bsdf = BSDF(si, eta, (SpecularReflection(KR, fresnel), SpecularTransmission(KT, 1.0, eta, mode)))
    else
        if g.remap_roughness == true
            urough = roughness_to_alpha(urough)
            vrough = roughness_to_alpha(vrough)
        end
        distrib = TrowbridgeReitzDistribution(urough, vrough)
        # skipping R/T black check
        fresnel = FresnelDielectric(1.0, eta)
        si.bsdf = BSDF(si, eta, (MicrofacetReflection(KR, distrib, fresnel), MicrofacetTransmission(KT, distrib, 1.0, eta, mode)))
    end
end

function albedo(m::Glass, si::SurfaceInteraction)::Spectrum
    KR = clamp.(m.Kr(si), 0, 1)
    KT = clamp.(m.Kt(si), 0, 1)
    eta = m.idx(si)
    
    # Fresnel reflectance at normal incidence for dielectric
    F0 = ((eta - 1.0) / (eta + 1.0))^2
    
    # At normal incidence:
    # - F0 fraction reflects (modulated by Kr)
    # - (1 - F0) fraction transmits (modulated by Kt)
    # For albedo (reflectance only), we only count the reflected portion
    return KR .* F0
end
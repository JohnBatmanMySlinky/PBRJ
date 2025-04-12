# PBR 9.2.1 Matte Material
struct Matte <: Material
    Kd::Texture{Spectrum}
    sigma::Texture{Float64}
    bump_map::Maybe{Texture{Float64}}
end

# Equivalent to PBR's ComputeScatteringFunction
function (m::Matte)(si::SurfaceInteraction, ::Bool, ::Type{T}) where T <: TransportMode
    # if bump map, update si
    if !(m.bump_map isa Nothing)
        bump!(m, si)
    end
    
    si.bsdf = BSDF(si)
    r = clamp.(m.Kd(si),0.0,1.0)

    @info "Spectrum Kd: $(r)"

    # TODO implement black body check
    sigma = clamp(m.sigma(si), 0, 90)
    if sigma == 0.0
        add!(si.bsdf, LambertianReflection(Spectrum(r)))
    else
        add!(si.bsdf, OrenNayarReflection(r, sigma))
    end
end


# PBR 9.3 Bump Mapping
function bump!(m::Material, si::SurfaceInteraction)
    original_uv = si.uv
    original_core_p = si.core.p
    original_core_n = si.core.n

    # evaulate displace
    displace = m.bump_map(si)
    
    # evaulate u displace
    du = .5 * (abs(si.dudx) + abs(si.dudy))
    if du == 0
        du = .0005
    end
    si.core.p = original_core_p + du * si.shading.dpdu
    si.uv = original_uv + Vec2(du, 0.0)
    si.core.n = normalize(cross(si.shading.dpdu, si.shading.dpdv) + du * si.dndu)
    u_displace = m.bump_map(si)

    # evaulate v displace
    dv = .5 * (abs(si.dvdx) + abs(si.dvdy))
    if dv == 0
        dv = .0005
    end
    si.core.p = original_core_p + dv * si.shading.dpdv
    si.uv = original_uv + Vec2(0.0, dv)
    si.core.n = normalize(cross(si.shading.dpdu, si.shading.dpdv) + dv * si.dndv)
    v_displace = m.bump_map(si)


    # compute bump mapped differential geometry
    dpdu = si.shading.dpdu + (u_displace - displace) / du .* Vec3(si.shading.n) + displace .* Vec3(si.shading.dndu)
    dpdv = si.shading.dpdv + (v_displace - displace) / dv .* Vec3(si.shading.n) + displace .* Vec3(si.shading.dndv)

    # reseting
    si.uv = original_uv 
    si.core.p = original_core_p
    si.core.n = original_core_n

    # update shaind geometry
    set_shading_geomerty!(si, dpdu, dpdv, si.shading.dndu, si.shading.dndv, false)
end
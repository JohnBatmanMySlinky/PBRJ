# PBR 9.2.1 Matte Material
struct Matte <: Material
    Kd::Texture
    sigma::Texture
    bump_map::Maybe{Texture}
end

# Equivalent to PBR's ComputeScatteringFunction
function (m::Matte)(si::SurfaceInteraction, ::Bool, ::Type{T}) where T <: TransportMode
    # if bump map, update si
    if !(m.bump_map isa Nothing)
        bump!(m, si)
    end
    
    si.bsdf = BSDF(si)
    r = Spectrum(clamp.(m.Kd(si),0,1)...)

    # TODO implement black body check
    sigma = clamp.(m.sigma(si), 0, 90)
    if sigma == Pnt3(0, 0, 0)
        add!(si.bsdf, LambertianReflection(r))
    else
        print("OrenNayer isn't implemented")
        @assert False
    end
end


# PBR 9.3 Bump Mapping
function bump!(m::Material, si::SurfaceInteraction)
    # make a deep copy
    si_eval = deepcopy(si)

    # evaulate u displace
    du = .5 * (abs(si.dudx) + abs(si.dudy))
    if du == 0
        du = .0005
    end
    si_eval.core.p = si.core.p + du * si.shading.dpdu
    si_eval.uv = si.uv + Vec2(du, 0.0)
    si_eval.core.n = normalize(cross(si.shading.dpdu, si.shading.dpdv) + du * si.dndu)
    u_displace = m.bump_map(si_eval)

    # evaulate v displace
    dv = .5 * (abs(si.dvdx) + abs(si.dvdy))
    if dv == 0
        dv = .0005
    end
    si_eval.core.p = si.core.p + dv * si.shading.dpdv
    si_eval.uv = si.uv + Vec2(0.0, dv)
    si_eval.core.n = normalize(cross(si.shading.dpdu, si.shading.dpdv) + dv * si.dndv)
    v_displace = m.bump_map(si_eval)

    # evaulate displace
    displace = m.bump_map(si)

    # compute bump mapped differential geometry
    dpdu = si.shading.dpdu + (u_displace - displace) / du .* Vec3(si.shading.n) + displace .* Vec3(si.shading.dndu)
    dpdv = si.shading.dpdv + (v_displace - displace) / dv .* Vec3(si.shading.n) + displace .* Vec3(si.shading.dndv)

    # update shaind geometry
    set_shading_geomerty!(si, dpdu, dpdv, si.shading.dndu, si.shading.dndv, false)
end
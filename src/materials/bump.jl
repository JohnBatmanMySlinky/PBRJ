# PBR 9.3 Bump Mapping
function bump!(m::Material, si::SurfaceInteraction)
    original_uv = si.uv
    original_core_p = si.core.p
    original_core_n = si.core.n

    # evaluate u displace
    du = .5 * (abs(si.dudx) + abs(si.dudy))
    if du == 0
        du = .0005
    end
    si.core.p = original_core_p + du * si.shading.dpdu
    si.uv = original_uv + Vec2(du, 0.0)
    si.core.n = normalize(cross(si.shading.dpdu, si.shading.dpdv) + du * si.dndu)
    u_displace = m.bump_map(si)

    # evaluate v displace
    dv = .5 * (abs(si.dvdx) + abs(si.dvdy))
    if dv == 0
        dv = .0005
    end
    si.core.p = original_core_p + dv * si.shading.dpdv
    si.uv = original_uv + Vec2(0.0, dv)
    si.core.n = normalize(cross(si.shading.dpdu, si.shading.dpdv) + dv * si.dndv)
    v_displace = m.bump_map(si)

    # Reset to original state before evaluating original displacement
    si.uv = original_uv
    si.core.p = original_core_p
    si.core.n = original_core_n

    # NOW evaluate original displace
    displace = m.bump_map(si)

    # compute bump mapped differential geometry
    dpdu = si.shading.dpdu + (u_displace - displace) / du .* Vec3(si.shading.n) + displace .* Vec3(si.shading.dndu)
    dpdv = si.shading.dpdv + (v_displace - displace) / dv .* Vec3(si.shading.n) + displace .* Vec3(si.shading.dndv)

    # update shading geometry
    set_shading_geomerty!(si, dpdu, dpdv, si.shading.dndu, si.shading.dndv, false)
end

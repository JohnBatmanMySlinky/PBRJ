# PBR 9.3 Bump Mapping
function bump!(m::Material, si::SurfaceInteraction)
    original_uv = si.uv
    original_core = si.core

    # evaluate u displace
    du = .5 * (abs(si.dudx) + abs(si.dudy))
    if du == 0
        du = .0005
    end
    si.core = Interaction(original_core.p + du * si.shading.dpdu, original_core.t, original_core.wo, normalize(cross(si.shading.dpdu, si.shading.dpdv) + du * si.dndu), original_core.mi)
    si.uv = original_uv + Vec2(du, 0.0)
    u_displace = m.bump_map(si)

    # evaluate v displace
    dv = .5 * (abs(si.dvdx) + abs(si.dvdy))
    if dv == 0
        dv = .0005
    end
    si.core = Interaction(original_core.p + dv * si.shading.dpdv, original_core.t, original_core.wo, normalize(cross(si.shading.dpdu, si.shading.dpdv) + dv * si.dndv), original_core.mi)
    si.uv = original_uv + Vec2(0.0, dv)
    v_displace = m.bump_map(si)

    # Reset to original state before evaluating original displacement
    si.uv = original_uv
    si.core = original_core

    # NOW evaluate original displace
    displace = m.bump_map(si)

    # compute bump mapped differential geometry
    dpdu = si.shading.dpdu + (u_displace - displace) / du .* Vec3(si.shading.n) + displace .* Vec3(si.shading.dndu)
    dpdv = si.shading.dpdv + (v_displace - displace) / dv .* Vec3(si.shading.n) + displace .* Vec3(si.shading.dndv)

    # update shading geometry
    set_shading_geomerty!(si, dpdu, dpdv, si.shading.dndu, si.shading.dndv, false)
end

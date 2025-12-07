# PBR 9.3 Bump Mapping
function bump!(m::Material, si::SurfaceInteraction)
    @info "SI AT THE TOP :\n\tp: $(si.core.p)\n\t:t: $(si.core.t)\n\two: $(si.core.wo)\n\tn: $(si.core.n)\n\tuv: $(si.uv)\n\tdpdu: $(si.dpdu)\n\tdpdv: $(si.dpdv)\n\tdndu: $(si.dndu)\n\tdndv: $(si.dndv)\n\tsn: $(si.shading.n)\n\tsdpdu: $(si.shading.dpdu)\n\tsdpdv: $(si.shading.dpdv)\n\t: $(si.dudx)\n\t: $(si.dudy)\n\t: $(si.dvdx)\n\t: $(si.dvdy)\n\t:dpdx: $(si.dpdx)\n\t:dpdy: $(si.dpdy)"

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
    @info "SI U_DISPLACE :\n\tp: $(si.core.p)\n\t:t: $(si.core.t)\n\two: $(si.core.wo)\n\tn: $(si.core.n)\n\tuv: $(si.uv)\n\tdpdu: $(si.dpdu)\n\tdpdv: $(si.dpdv)\n\tdndu: $(si.dndu)\n\tdndv: $(si.dndv)\n\tsn: $(si.shading.n)\n\tsdpdu: $(si.shading.dpdu)\n\tsdpdv: $(si.shading.dpdv)\n\t: $(si.dudx)\n\t: $(si.dudy)\n\t: $(si.dvdx)\n\t: $(si.dvdy)\n\t:dpdx: $(si.dpdx)\n\t:dpdy: $(si.dpdy)"
    u_displace = m.bump_map(si)
    @info "u_displace: $u_displace"

    # evaluate v displace
    dv = .5 * (abs(si.dvdx) + abs(si.dvdy))
    if dv == 0
        dv = .0005
    end
    si.core.p = original_core_p + dv * si.shading.dpdv
    si.uv = original_uv + Vec2(0.0, dv)
    si.core.n = normalize(cross(si.shading.dpdu, si.shading.dpdv) + dv * si.dndv)
    @info "SI V_DISPLACE :\n\tp: $(si.core.p)\n\t:t: $(si.core.t)\n\two: $(si.core.wo)\n\tn: $(si.core.n)\n\tuv: $(si.uv)\n\tdpdu: $(si.dpdu)\n\tdpdv: $(si.dpdv)\n\tdndu: $(si.dndu)\n\tdndv: $(si.dndv)\n\tsn: $(si.shading.n)\n\tsdpdu: $(si.shading.dpdu)\n\tsdpdv: $(si.shading.dpdv)\n\t: $(si.dudx)\n\t: $(si.dudy)\n\t: $(si.dvdx)\n\t: $(si.dvdy)\n\t:dpdx: $(si.dpdx)\n\t:dpdy: $(si.dpdy)"
    v_displace = m.bump_map(si)
    @info "v_displace: $v_displace"

    # Reset to original state before evaluating original displacement
    si.uv = original_uv 
    si.core.p = original_core_p
    si.core.n = original_core_n
    @info "SI DISPLACE :\n\tp: $(si.core.p)\n\t:t: $(si.core.t)\n\two: $(si.core.wo)\n\tn: $(si.core.n)\n\tuv: $(si.uv)\n\tdpdu: $(si.dpdu)\n\tdpdv: $(si.dpdv)\n\tdndu: $(si.dndu)\n\tdndv: $(si.dndv)\n\tsn: $(si.shading.n)\n\tsdpdu: $(si.shading.dpdu)\n\tsdpdv: $(si.shading.dpdv)\n\t: $(si.dudx)\n\t: $(si.dudy)\n\t: $(si.dvdx)\n\t: $(si.dvdy)\n\t:dpdx: $(si.dpdx)\n\t:dpdy: $(si.dpdy)"

    
    # NOW evaluate original displace
    displace = m.bump_map(si)
    @info "displace: $displace"

    # compute bump mapped differential geometry
    @info "WHAT\n\t$(si.shading.dpdu)\n\t$(du)\n\t$(si.shading.n)\n\t$(si.shading.dndu)"
    @info "WHAT\n\t$(si.shading.dpdv)\n\t$(dv)\n\t$(si.shading.n)\n\t$(si.shading.dndv)"
    dpdu = si.shading.dpdu + (u_displace - displace) / du .* Vec3(si.shading.n) + displace .* Vec3(si.shading.dndu)
    dpdv = si.shading.dpdv + (v_displace - displace) / dv .* Vec3(si.shading.n) + displace .* Vec3(si.shading.dndv)

    @info "SI DUR :\n\tp: $(si.core.p)\n\t:t: $(si.core.t)\n\two: $(si.core.wo)\n\tn: $(si.core.n)\n\tuv: $(si.uv)\n\tdpdu: $(si.dpdu)\n\tdpdv: $(si.dpdv)\n\tdndu: $(si.dndu)\n\tdndv: $(si.dndv)\n\tsn: $(si.shading.n)\n\tsdpdu: $(si.shading.dpdu)\n\tsdpdv: $(si.shading.dpdv)\n\t: $(si.dudx)\n\t: $(si.dudy)\n\t: $(si.dvdx)\n\t: $(si.dvdy)\n\t:dpdx: $(si.dpdx)\n\t:dpdy: $(si.dpdy)"

    @info "dpdu: $dpdu, dpdv: $dpdv"

    # update shading geometry
    set_shading_geomerty!(si, dpdu, dpdv, si.shading.dndu, si.shading.dndv, false)
    @info "SI AFTER :\n\tp: $(si.core.p)\n\t:t: $(si.core.t)\n\two: $(si.core.wo)\n\tn: $(si.core.n)\n\tuv: $(si.uv)\n\tdpdu: $(si.dpdu)\n\tdpdv: $(si.dpdv)\n\tdndu: $(si.dndu)\n\tdndv: $(si.dndv)\n\tsn: $(si.shading.n)\n\tsdpdu: $(si.shading.dpdu)\n\tsdpdv: $(si.shading.dpdv)\n\t: $(si.dudx)\n\t: $(si.dudy)\n\t: $(si.dvdx)\n\t: $(si.dvdy)\n\t:dpdx: $(si.dpdx)\n\t:dpdy: $(si.dpdy)"
end
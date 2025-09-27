# PBR 9.2.1 Matte Material
struct Matte{
        K <: AbstractTexture{Spectrum}, 
        S <: AbstractTexture{Float64}, 
        B <: Maybe{AbstractTexture{Float64}}
    } <: Material
    Kd::K
    sigma::S
    bump_map::B
    name::String

    function Matte(
        name::String,
        k::K=ConstantTexture(spectrum_from_float(0.5, 0.5, 0.5)),
        s::S=ConstantTexture(0.0),
        b::B=nothing
    )::Matte where {
        K <: AbstractTexture{Spectrum},
        S <: AbstractTexture{Float64},
        B <: Maybe{AbstractTexture{Float64}}
    }
        return new{K, S, B}(k, s, b, name)
    end
end

# Equivalent to PBR's ComputeScatteringFunction
function (m::Matte)(si::SurfaceInteraction, ::Bool, ::Type{T}) where T <: TransportMode
    # if bump map, update si
    if !(m.bump_map isa Nothing)
        @info "BUMP BUMP BUMP"
        @info "Surface Interaction Pre Bump: $si"
        bump!(m, si)
        @info "Surface Interaction Post Bump: $si"
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

    # evaluate u displace
    du = .5 * (abs(si.dudx) + abs(si.dudy))
    if du == 0
        du = .0005
    end
    si.core.p = original_core_p + du * si.shading.dpdu
    si.uv = original_uv + Vec2(du, 0.0)
    si.core.n = normalize(cross(si.shading.dpdu, si.shading.dpdv) + du * si.dndu)
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
    v_displace = m.bump_map(si)
    @info "v_displace: $v_displace"

    # Reset to original state before evaluating original displacement
    si.uv = original_uv 
    si.core.p = original_core_p
    si.core.n = original_core_n
    
    # NOW evaluate original displace
    displace = m.bump_map(si)
    @info "displace: $displace"

    # compute bump mapped differential geometry
    dpdu = si.shading.dpdu + (u_displace - displace) / du .* Vec3(si.shading.n) + displace .* Vec3(si.shading.dndu)
    dpdv = si.shading.dpdv + (v_displace - displace) / dv .* Vec3(si.shading.n) + displace .* Vec3(si.shading.dndv)

    @info "SI DUR :\n\tp: $(si.core.p)\n\t:t: $(si.core.t)\n\two: $(si.core.wo)\n\tn: $(si.core.n)\n\tuv: $(si.uv)\n\tdpdu: $(si.dpdu)\n\tdpdv: $(si.dpdv)\n\tdndu: $(si.dndu)\n\tdndv: $(si.dndv)\n\tsn: $(si.shading.n)\n\tsdpdu: $(si.shading.dpdu)\n\tsdpdv: $(si.shading.dpdv)\n\t: $(si.dudx)\n\t: $(si.dudy)\n\t: $(si.dvdx)\n\t: $(si.dvdy)\n\t:dpdx: $(si.dpdx)\n\t:dpdy: $(si.dpdy)"

    @info "dpdu: $dpdu, dpdv: $dpdv"

    # update shading geometry
    set_shading_geomerty!(si, dpdu, dpdv, si.shading.dndu, si.shading.dndv, false)
end
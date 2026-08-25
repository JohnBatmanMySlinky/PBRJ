struct Interaction
    # world coordinates
    p::Pnt3
    # time of intersection
    t::Float64
    # negative of ray direciton
    # direction from intersection to viewer
    wo::Vec3
    # surface normal in world coordinates
    n::Nml3
    mi::MediumInterface
end

function Interaction()
    return Interaction(Pnt3(0.0), 0.0, Vec3(0), Nml3(0), NO_MEDIUM_INTERFACE)
end

function Interaction(r::AbstractRay)::Interaction
    return Interaction(r.origin, r.t, -r.direction, Nml3(r.direction), NO_MEDIUM_INTERFACE)
end

function Interaction(r::AbstractRay, n::Nml3)::Interaction
    return Interaction(r.origin, r.t, -r.direction, n, NO_MEDIUM_INTERFACE)
end

# PBRT 2.10 
# for other types of interacion points where the notation of an outgoing direction doesnt apply
# ie those found by randomly sampling points on a surface of a shape wo has the value Vec3(0)
function Interaction(p::Pnt3, t::Float64, n::Nml3)::Interaction
    return Interaction(p, t, Vec3(0.0, 0.0, 0.0), n, NO_MEDIUM_INTERFACE)
end

function Interaction(p::Pnt3, t::Float64)::Interaction
    return Interaction(p, t, Vec3(0.0, 0.0, 0.0), Nml3(0.0, 0.0, 0.0), NO_MEDIUM_INTERFACE)
end

function Interaction(p::Pnt3, t::Float64, wo::Vec3, n::Nml3)::Interaction
    return Interaction(p, t, wo, n, NO_MEDIUM_INTERFACE)
end

function Interaction(p::Pnt3, t::Float64, wo::Vec3, n::Nml3, m::Maybe{Union{Handle{:Medium}, AbstractMedium}})::Interaction
    return Interaction(p, t, wo, n, MediumInterface(m))
end

function Interaction(p::Pnt3, t::Float64, wo::Vec3, mi::MediumInterface)::Interaction
    return Interaction(p, t, wo, Nml3(0.0, 0.0, 0.0), mi)
end

function Interaction(p::Pnt3, t::Float64, wo::Vec3, m::Union{Handle{:Medium}, AbstractMedium})::Interaction
    return Interaction(p, t, wo, Nml3(0.0, 0.0, 0.0), MediumInterface(m))
end

function is_surface_interaction(isect::Interaction)::Bool
    return isect.n != Nml3(0, 0, 0)
end

struct ShadingInteraction
    n::Nml3
    dpdu::Vec3
    dpdv::Vec3
    dndu::Nml3
    dndv::Nml3
end

mutable struct SurfaceInteraction
    core::Interaction
    shading::ShadingInteraction
    uv::Pnt2

    dpdu::Vec3
    dpdv::Vec3
    dndu::Nml3
    dndv::Nml3

    shape::Maybe{Shape}
    primitive::Maybe{Primitive}
    bsdf::Maybe{AbstractBSDF}
    bssrdf::Maybe{AbstractBSSRDF}

    # more partials
    dudx::Float64
    dudy::Float64
    dvdx::Float64
    dvdy::Float64
    dpdx::Vec3
    dpdy::Vec3
end

function is_surface_interaction(isect::SurfaceInteraction)::Bool
    return isect.core.n != Nml3(0, 0, 0)
end

function InstantiateSurfaceInteraction(
    p::Pnt3, 
    t::Float64,
    wo::Vec3,
    uv::Pnt2,
    dpdu::Vec3,
    dpdv::Vec3,
    dndu::Nml3,
    dndv::Nml3,
    shape::Maybe{Shape}=nothing,
    primitive::Maybe{Primitive}=nothing,
    bsdf::Maybe{AbstractBSDF}=nothing,
    bssrdf::Maybe{AbstractBSSRDF}=nothing
)::SurfaceInteraction
    n = Nml3(normalize(cross(dpdu, dpdv)))

    core = Interaction(p, t, wo, n)
    shading = ShadingInteraction(n, dpdu, dpdv, dndu, dndv)

    if !(shape isa Nothing)
        if shape.core.reverse_orientation ⊻ shape.core.transform_swaps_handedness
            core = Interaction(core.p, core.t, core.wo, core.n * -1, core.mi)
            shading = ShadingInteraction(shading.n * -1, shading.dpdu, shading.dpdv, shading.dndu, shading.dndv)
        end
    end

    return SurfaceInteraction(
        core, 
        shading,
        uv,
        dpdu,
        dpdv,
        dndu,
        dndv,
        shape,
        primitive,
        bsdf,
        bssrdf,
        0,
        0,
        0,
        0,
        Vec3(0),
        Vec3(0),
    )
end

function empty_surface_interation(s::Shape)::SurfaceInteraction
    return InstantiateSurfaceInteraction(
        Pnt3(1,1,1), 
        0.0,
        Vec3(1,1,1),
        Pnt2(.5, .5),
        Vec3(1,0,0),
        Vec3(0,1,0),
        Nml3(1,0,0),
        Nml3(0,1,0),
        s,
        nothing,
        nothing,
    )
end

function empty_surface_interation()::SurfaceInteraction
    return InstantiateSurfaceInteraction(
        Pnt3(1, 1, 1), 
        0.0,
        Vec3(1, 1, 1),
        Pnt2(.5, .5),
        Vec3(1, 0, 0),
        Vec3(0, 1, 0),
        Nml3(1, 0, 0),
        Nml3(0, 1, 0),
        nothing,
        nothing,
        nothing,
    )
end

###########################
### Medium Interactions ###
###########################

struct MediumInteraction
    core::Interaction
    phase::Maybe{AbstractPhaseFunction}

    function MediumInteraction(p::Pnt3, t::Float64, wo::Vec3, m::Union{Handle{:Medium}, AbstractMedium}, phase::Maybe{AbstractPhaseFunction})
        return new(Interaction(p, t, wo, MediumInterface(m)), phase)
    end
end

function is_valid(m::MediumInteraction)::Bool
    return !(m.phase isa Nothing)
end

#################
### Spawn Ray ###
#################
function spawn_ray(interaction::Interaction, direction::Vec3)::RayDifferential
    # JOHN HACK: OffsetRayOrigin
    o = interaction.p + ShadowEpsilon * direction
    return RayDifferential(Ray(o, direction, interaction.t, typemax(Float64), get_medium(interaction, direction)))
end

function spawn_ray_to(interaction::Interaction, p2::Pnt3)::RayDifferential
    d::Vec3 = p2 - interaction.p
    o = interaction.p + ShadowEpsilon * d
    return RayDifferential(Ray(o, d, interaction.t, 1.0 - ShadowEpsilon, get_medium(interaction, d)))
end

function spawn_ray_to(interaction::Interaction, it::Interaction)::RayDifferential
    o = interaction.p + ShadowEpsilon * (it.p - interaction.p)
    target = it.p + ShadowEpsilon * (o - it.p)
    d::Vec3 = target - o
    return RayDifferential(Ray(o, d, interaction.t, 1.0 - ShadowEpsilon, get_medium(interaction, d)))
end

#########################################
## Compute Scattering at interacttion ###
#########################################
function compute_scattering!(si::SurfaceInteraction, ray::AbstractRay, allow_multiple_lobes::Bool=false, ::Type{T}=Radiance) where T <: TransportMode
    compute_differentials!(si, ray)
    compute_scattering!(si.primitive, si, allow_multiple_lobes, T)
end

function compute_scattering!(p::Primitive, si::SurfaceInteraction, allow_multiple_lobes::Bool, ::Type{T}) where T <: TransportMode
    if !(p.material isa Nothing)
        # evaluate the bsdf
        material = get_material(p.material)
        material(si, allow_multiple_lobes, T)
    end
    # @assert (dot(si.core.n, si.shading.n)) >= 0
end

#########################################
#### instantiate differentials ##########
#########################################
function compute_differentials!(si::SurfaceInteraction, ray::RayDifferential)
    if !ray.has_differentials
        si.dudx = 0.0
        si.dudy = 0.0
        si.dvdx = 0.0
        si.dvdy = 0.0
        si.dpdx = Vec3(0,0,0)
        si.dpdy = Vec3(0,0,0)
        return
    end

    # Estimate screen change in p and (u, v).
    # Compute auxiliary intersection points with plane.
    d = dot(si.core.n, Vec3(si.core.p))
    tx = -(dot(si.core.n, Vec3(ray.rx_origin)) - d) / dot(si.core.n, ray.rx_direction)
    px = ray.rx_origin + tx * ray.rx_direction
    ty = -(dot(si.core.n, Vec3(ray.ry_origin)) - d) / dot(si.core.n, ray.ry_direction)
    py = ray.ry_origin + ty * ray.ry_direction

    si.dpdx = px - si.core.p
    si.dpdy = py - si.core.p

    # Compute (u, v) offsets at auxiliary points.
    # Choose two dimensions for ray offset computation.
    n = abs.(si.core.n)
    if (abs(n.x) > abs(n.y)) && (abs(n.x) > abs(n.z))
        dim = Pnt2i(1, 2)
    elseif abs(n.y) > abs(n.z)
        dim = Pnt2i(0, 2)
    else
        dim = Pnt2i(0, 1)
    end
    # @info "Computed Differentials: $(si.dpdu), $(si.dpdv)"
    # @info "Computed Differentials: $dim"

    # Initialization for offset computation.
    d0 = dim[0+1]+1
    d1 = dim[1+1]+1
    a = Mat2(si.dpdu[d0], si.dpdu[d1], si.dpdv[d0], si.dpdv[d1])
    bx = Pnt2(px[d0] - si.core.p[d0], px[d1] - si.core.p[d1])
    by = Pnt2(py[d0] - si.core.p[d0], py[d1] - si.core.p[d1])
    sx = a \ bx
    sy = a \ by
    # @info "Computed differentials: $a $bx $by $sx $sy"

    si.dudx, si.dvdx = any(.!isfinite.(sx)) ? (0, 0) : sx
    si.dudy, si.dvdy = any(.!isfinite.(sy)) ? (0, 0) : sy
end

function set_shading_geomerty!(si::SurfaceInteraction, dpdus::Vec3, dpdvs::Vec3, dndus::Nml3, dndvs::Nml3, orientation_is_authoritative::Bool)
    new_n = Nml3(normalize(cross(dpdus, dpdvs)))
    if orientation_is_authoritative
        si.core = Interaction(si.core.p, si.core.t, si.core.wo, face_forward(si.core.n, new_n), si.core.mi)
    else
        new_n = face_forward(new_n, si.core.n)
    end
    si.shading = ShadingInteraction(new_n, dpdus, dpdvs, dndus, dndvs)
end

#########################################
#### Light emitted ######################
#########################################
function le(si::SurfaceInteraction, w::Vec3)::Spectrum
    if si.primitive.area_light isa Nothing
        return spectrum_from_float(0.0)
    else
        return L(si.primitive.area_light, si.core.n, w, Pnt2(rand(), rand())) # JOHN WHAT
    end
end
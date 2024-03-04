mutable struct Interaction
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
    return Interaction(Pnt3(0), 0.0, Vec3(0), Nml3(0), MediumInterface(nothing))
end

function Interaction(r::AbstractRay)::Interaction
    return Interaction(r.origin, r.t, -r.direction, Nml3(r.direction), MediumInterface(nothing))
end

function Interaction(r::AbstractRay, n::Nml3)::Interaction
    return Interaction(r.origin, r.t, -r.direction, n, MediumInterface(nothing))
end

# PBRT 2.10 
# for other types of interacion points where the notation of an outgoing direction doesnt apply
# ie those found by randomly sampling points on a surface of a shape wo has the value Vec3(0)
function Interaction(p::Pnt3, t::Float64, n::Nml3)::Interaction
    return Interaction(p, t, Vec3(0.0), n, MediumInterface(nothing))
end

function Interaction(p::Pnt3, t::Float64, wo::Vec3, n::Nml3)::Interaction
    return Interaction(p, t, wo, n, MediumInterface(nothing))
end

function Interaction(p::Pnt3, t::Float64, wo::Vec3, mi::MediumInterface)::Interaction
    return Interaction(p, t, wo, Nml3(0), mi)
end

function Interaction(p::Pnt3, t::Float64, wo::Vec3, m::AbstractMedium)::Interaction
    return Interaction(p, t, wo, Nml3(0), MediumInterface(m))
end

mutable struct ShadingInteraction
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

    # more partials
    dudx::Float64
    dudy::Float64
    dvdx::Float64
    dvdy::Float64
    dpdx::Vec3
    dpdy::Vec3
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
)::SurfaceInteraction
    n = Nml3(normalize(cross(dpdu, dpdv)))

    core = Interaction(p, t, wo, n)
    shading = ShadingInteraction(n, dpdu, dpdv, dndu, dndv)

    if !(shape isa Nothing)
        if shape.core.reverse_orientation ⊻ shape.core.transform_swaps_handedness
            core.n = core.n * -1
            shading.n = shading.n * -1
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
        Pnt3(1), 
        0.0,
        Vec3(1,1,1),
        Pnt2(.5, .5),
        Vec3(1,0,0),
        Vec3(0,1,0),
        Nml3(1,0,0),
        Nml3(0,1,0),
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

    function MediumInteraction(p::Pnt3, t::Float64, wo::Vec3, m::AbstractMedium, phase::Maybe{AbstractPhaseFunction})
        return new(Interaction(p, t, wo, MediumInterface(m)), phase)
    end
end

function is_valid(m::MediumInteraction)::Bool
    return !(m.phase isa Nothing)
end

#################
### Spawn Ray ###
#################
function spawn_ray(p0::Union{SurfaceInteraction, MediumInteraction}, p1::Interaction)::RayDifferential
    return spawn_ray(p0.core, p1)
end

function spawn_ray(interaction::Interaction, direction::Vec3, delta::Float64 = 1e-6)::RayDifferential
    origin = interaction.p .+ delta .* direction
    return RayDifferential(Ray(origin, direction, interaction.t, typemax(Float64), get_medium(interaction, direction)))
end

function spawn_ray(interaction::MediumInteraction, direction::Vec3, delta::Float64=1e-6)::RayDifferential
    origin = interaction.core.p .+ delta .* direction
    return RayDifferential(Ray(origin, direction, interaction.core.t, typemax(Float64), get_medium(interaction.core, direction)))
end

function spawn_ray(p0::Interaction, p1::Interaction, delta::Float64 = 1e-6,)::RayDifferential
    direction::Vec3 = p1.p - p0.p
    origin = p0.p .+ delta .* direction
    return RayDifferential(Ray(origin, direction, p0.t, typemax(Float64), get_medium(p0, direction)))
end

function spawn_shadow_ray(p0::Interaction, p1::Interaction, delta::Float64 = 1e-6,)::RayDifferential
    direction::Vec3 = p1.p - p0.p
    origin = p0.p .+ delta .* direction
    return RayDifferential(Ray(origin, direction, p0.t, 1.0-.0001, get_medium(p0, direction))) # JOHN HACK: this has to be 0, p0.t for s==1 bdpt to work?
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
        p.material(si, allow_multiple_lobes, T)
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
    d = -dot(si.core.n, Vec3(si.core.p))
    tx = (-dot(si.core.n, Vec3(ray.rx_origin)) - d) / dot(si.core.n, ray.rx_direction)
    px = ray.rx_origin + tx * ray.rx_direction
    ty = (-dot(si.core.n, Vec3(ray.ry_origin)) - d) / dot(si.core.n, ray.ry_direction)
    py = ray.ry_origin + ty * ray.ry_direction

    si.dpdx = px - si.core.p
    si.dpdy = py - si.core.p

    # Compute (u, v) offsets at auxiliary points.
    # Choose two dimensions for ray offset computation.
    n = abs.(si.core.n)
    if n[1] > n[2] && n[1] > n[3]
        dim = Pnt2(2, 3)
    elseif n[2] > n[3]
        dim = Pnt2(1, 3)
    else
        dim = Pnt2(1, 2)
    end

    # Initialization for offset computation.
    a = Mat2([
        si.shading.dpdu[Int(dim[1])]
        si.shading.dpdv[Int(dim[1])]
        si.shading.dpdu[Int(dim[2])]
        si.shading.dpdv[Int(dim[2])]
    ])
    bx = Pnt2(
        px[Int(dim[1])] - si.core.p[Int(dim[1])],
        px[Int(dim[2])] - si.core.p[Int(dim[2])]
    )
    by = Pnt2(
        py[Int(dim[1])] - si.core.p[Int(dim[1])],
        py[Int(dim[2])] - si.core.p[Int(dim[2])]
    )
    sx = a \ bx
    sy = a \ by

    si.dudx, si.dvdx = any(isnan.(sx)) ? (0, 0) : sx
    si.dudy, si.dvdy = any(isnan.(sy)) ? (0, 0) : sy
end

function set_shading_geomerty!(si::SurfaceInteraction, dpdus::Vec3, dpdvs::Vec3, dndus::Nml3, dndvs::Nml3, orientation_is_authoritative::Bool)
    si.shading.n = normalize(cross(dpdus, dpdvs))

    if orientation_is_authoritative
        si.core.n = face_forward(si.core.n, si.shading.n)
    else
        si.shading.n = face_forward(si.shading.n, si.core.n)
    end

    si.shading.dpdu = dpdus
    si.shading.dpdv = dpdvs
    si.shading.dndu = dndus
    si.shading.dndv = dndvs
end

#########################################
#### Light emitted ######################
#########################################
function le(si::SurfaceInteraction, w::Vec3)::Spectrum
    if si.primitive.area_light isa Nothing
        return spectrum_from_float(0.0)
    else
        return si.primitive.area_light.Lemit
    end
end
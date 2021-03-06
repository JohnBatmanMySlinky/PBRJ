mutable struct Interaction
    # world coordinates
    p::Pnt3
    # time of intersection
    time::Float32
    # negative of ray direciton
    # direction from intersection to viewer
    wo::Vec3
    # surface normal in world coordinates
    n::Nml3
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

    shape::Shape
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
    time::Float64,
    wo::Vec3,
    uv::Pnt2,
    dpdu::Vec3,
    dpdv::Vec3,
    dndu::Nml3,
    dndv::Nml3,
    shape::Shape,
    primitive::Maybe{Primitive}=nothing,
    bsdf::Maybe{AbstractBSDF}=nothing,
)::SurfaceInteraction
    n = normalize(cross(dpdu, dpdv))

    core = Interaction(p, time, wo, n)
    shading = ShadingInteraction(n, dpdu, dpdv, dndu, dndv)
    return SurfaceInteraction(
        core, 
        shading,
        uv,
        dpdu,
        dpdv,
        dndu,
        dndv,
        shape,
        nothing,
        nothing,
        0,
        0,
        0,
        0,
        Vec3(0,0,0),
        Vec3(0,0,0),
    )
end

#################
### Spawn Ray ###
#################
function spawn_ray(p0::SurfaceInteraction, p1::Interaction)::Ray
    return spawn_ray(p0.core, p1)
end

function spawn_ray(interaction::Interaction, direction::Vec3, delta::Float64 = 1e-6)::Ray
    origin = interaction.p .+ delta .* direction
    return Ray(origin, direction, interaction.time, typemax(Float64))
end

function spawn_ray(p0::Interaction, p1::Interaction, delta::Float64 = 1e-6,)::Ray
    direction = p1.p - p0.p
    origin = p0.p .+ delta .* direction
    return Ray(origin, direction, p0.time, typemax(Float64))
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
    # TODO WHY FAIL
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

function set_shading_geomerty!(si::SurfaceInteraction, dpdus::Vec3, dpdvs::Vec3, dndus::Nml3, dndvs::Nml3, ::Bool)
    # TODO normal orientation
    # missing face forward logic
    si.shading.n = normalize(cross(dpdus, dpdvs))
    si.shading.dpdu = dpdus
    si.shading.dpdv = dpdvs
    si.shading.dndu = dndus
    si.shading.dndv = dndvs
end

#########################################
#### Light emitted ######################
#########################################
function le(si::SurfaceInteraction, ::Vec3)::Spectrum
    return Spectrum(0, 0, 0)
end
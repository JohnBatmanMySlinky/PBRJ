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
        nothing
    )
end

#################
### Spawn Ray ###
#################
function spawn_ray(p0::SurfaceInteraction, p1::Interaction)::Ray
    return spawn_ray(p0.core, p1)
end

function spawn_ray(si::SurfaceInteraction, direction::Vec3, delta::Float64 = 1e-6)::Ray
    origin = si.core.p .+ delta .* direction
    return Ray(origin, direction, si.core.time, typemax(Float64))
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
    # compute_differentials!()
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
#### Light emitted ######################
#########################################
function le(::SurfaceInteraction, ::Vec3)::Spectrum
    #TODO 0 cause no area lights yet
    return Spectrum(0, 0, 0)
end
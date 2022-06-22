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
    primitive::Maybe{Primitive}=nothing
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
        nothing
    )
end
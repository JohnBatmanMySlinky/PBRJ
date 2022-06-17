mutable struct Interaction
    # world coordinates
    p::Vec3
    # time of intersection
    time::Float32
    # negative of ray direciton
    # direction from intersection to viewer
    wo::Vec3
    # surface normal in world coordinates
    n::Vec3
end

mutable struct ShadingInteraction
    n::Vec3
    dpdu::Vec3
    dpdv::Vec3
    dndu::Vec3
    dndv::Vec3
end

mutable struct SurfaceInteraction
    core::Interaction
    shading::ShadingInteraction
    uv::Vec2

    dpdu::Vec3
    dpdv::Vec3
    dndu::Vec3
    dndv::Vec3

    shape::Shape
    primitive::Maybe{GeometricPrimitive}
end

function InstantiateSurfaceInteraction(
    p::Vec3, 
    time::Float64,
    wo::Vec3,
    uv::Vec2,
    dpdu::Vec3,
    dpdv::Vec3,
    dndu::Vec3,
    dndv::Vec3,
    shape::Shape,
    primitive::Maybe{GeometricPrimitive}=nothing
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
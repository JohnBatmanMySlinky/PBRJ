struct SDF_Box <: ImplicitSurface
    core::ShapeCore
    b::Vec3
    bounding_sphere::Sphere
    function SDF_Box(sc::ShapeCore, b::Vec3)
        bs_center = Pnt3(0,0,0)
        return new(sc, b, Sphere(bs_center, maximum(b) * 2.0 * 1.1))
    end
end

function f(s::SDF_Box, t::Float64, ray::AbstractRay)::Float64
    pp = at(ray, t)
    return f(s, pp)
end

function f(s::SDF_Box, p::Pnt3)::Float64
    q = abs.(p) - s.b
    return length_pbrt(
        max.(q, 0.0)
    ) + min(
        maximum(q),
        0.0
    )
end

function ObjectBounds(s::SDF_Box)::Bounds3
    r = s.bounding_sphere.radius
    return Bounds3(
        Pnt3(-r, -r, -r),
        Pnt3(r, r, r),
    )
end
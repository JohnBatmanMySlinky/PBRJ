struct SDF_Sphere <: ImplicitSurface
    core::ShapeCore
    r::Float64
    bounding_sphere::Sphere
    function SDF_Sphere(sc::ShapeCore, r::Float64)
        bs_center = Pnt3(0,0,0)
        return new(sc, r, Sphere(bs_center, r * 1.1))
    end
end

function f(s::SDF_Sphere, t::Float64, ray::AbstractRay)::Float64
    pp = at(ray, t)
    return f(s, pp)
end

function f(s::SDF_Sphere, p::Pnt3)::Float64
    return length_pbrt(p) - s.r
end

function ObjectBounds(s::SDF_Sphere)::Bounds3
    r = s.bounding_sphere.radius
    return Bounds3(
        Pnt3(-r, -r, -r),
        Pnt3(r, r, r),
    )
end
struct GoursatSurface <: ImplicitSurface
    core::ShapeCore
    a::Float64
    b::Float64
    magic::Float64 # equivalent to wolfram's c
    bounding_sphere::Sphere

    function GoursatSurface(
        core::ShapeCore
        a::Float64
        b::Float64
        magic::Float64 # equivalent to wolfram's c
    )
        r = goursat_bounding_sphere_radius(a, b, magic)
        bounding_sphere = Sphere(ShapeCore(), r)
        return new(core, a, b, magic, bounding_sphere)
    end
end

function f(g::GoursatSurface, t::Float64, ray::AbstractRay)::Float64
    pp = at(ray, t)
    return f(a, b, magic, pp)
end

function f(g::GoursatSurface, pp::Pnt3)::Float64
    return f(g.a, g.b, g.magic, pp)
end

function f(a::Float64, b::Float64, magic::Float64, ray::AbstractRay, t::Float64)::Float64
    pp = at(ray, t)
    return f(a, b, magic, pp)
end

function f(a::Float64, b::Float64, magic::Float64, pp::Pnt3)::Float64
    squared_term = pp.x^2 + pp.y^2 + pp.z^2
    return pp.x^4 + pp.y^4 + pp.z^4 + 
            a * squared_term^2 +
            b * squared_term +
            magic
end

function goursat_bounding_sphere_radius(a::Float64, b::Float64, magic::Float64)::Float64
    # this is ugly

    # The Plan
    # ----------------------------------
    # for the goursat surface, we knows the shape, roughly.
    # so shoot some intelligently picked rays from the origin
    # find the intersections, pad and roll with it.

    # due to symmetry of this surface I think we only need one ray
    # this is done in object space

    # WARNING
    # this method fails on the wolfram case of a=-1, b=1, c=-1
    # ----------------------------------

    # test case 1: the corner
    r = Ray(Pnt3(0,0,0), Vec3(-1.0, -1.0, -1.0), 0, typemax(Float64))
    tmp_solve = (x -> f(r, x, a, b, magic))
    solutions = find_zeros(tmp_solve, 0.0, 5.0) # a random guess here...
    @assert length(solutions) > 0
    return maximum(solutions)
end

function ObjectBounds(g::GoursatSurface)::Bounds3
    r = g.bounding_sphere.radius
    return Bounds3(
        Pnt3(-r, -r, -r) * 1.1,
        Pnt3(r, r, r) * 1.1,
    )
end
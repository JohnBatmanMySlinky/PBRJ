struct XZRectangle <: Shape
    core::ShapeCore
    x::Pnt2
    z::Pnt2
    k::Float64

    function XZRectangle(t::Transformation, x::Pnt2, z::Pnt2, k::Float64)
        return new(
            ShapeCore(t, Inv(t)),
            x,
            z
        )
    end
end

function ObjectBounds(xz::XZRectangle)
    return Bounds3(
        Pnt3(xz.x[1], xz.k - .00001, xz.z[1]),
        Pnt3(xz.x[2], xz.k + .00001, xz.z[2]),
    )
end

function Intersect(xz::XZRectangle, r::AbstractRay)
    r = xz.core.world_to_object(r)

    t = (xz.k - r.origin[2]) / r.direction[2]
    if (t < r.time) || (t > r.tMax)
        return false, nothing, nothing
    end

    x = r.origin[1] + t * r.direction[1]
    z = r.origin[3] + t * r.direction[3]
    if (x < xz.x[1]) || (x > xz.x[2]) || (z < xz.z[1]) || (z > xz.z[2])
        return false, nothing, nothing
    end
    u = (x-xz.x[1]) / (xz.x[2] - xz.x[1])
    v = (z-xz.z[1]) / (xz.z[2] - xz.z[1])
    p = at(r, t)
    n = Nml3(0, 1, 0)

    # TODO IS THIS RIGHT??
    _, dpdu, dpdv = orthonormal_basis(Vec3(0,1,0))

    # instantiate surface interaction
    interaction = InstantiateSurfaceInteraction(
        p,
        t,
        -r.direction,
        Pnt2(u, v),
        dpdu,
        dpdv,
        Nml3(0,0,0),
        Nml3(0,0,0),
        xz
    )

    # because normal is defined as cross(dpdu, dpdv)
    interaction.core.n = Nml3(0,1,0)
    interaction.shading.n = Nml3(0,1,0)

    # transform back to world coordinates
    interaction = xz.core.object_to_world(interaction)

    return true, t, interaction
end
############################
##### XZ ###################
############################

struct XZRectangle <: Shape
    core::ShapeCore
    x::Pnt2
    z::Pnt2
    k::Float64

    function XZRectangle(t::Transformation, x::Pnt2, z::Pnt2, k::Float64, reverse_orientation::Bool, transform_swaps_handedness::Bool)
        return new(
            ShapeCore(t, Inv(t), reverse_orientation, transform_swaps_handedness),
            x,
            z,
            k
        )
    end
end

function ObjectBounds(xz::XZRectangle)
    return Bounds3(
        Pnt3(xz.x[1], xz.k - .00001, xz.z[1]),
        Pnt3(xz.x[2], xz.k + .00001, xz.z[2]),
    )
end

function intersect(xz::XZRectangle, r::AbstractRay)::Tuple{Bool, Maybe{Float64}, Maybe{SurfaceInteraction}}
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


function intersect_p(xz::XZRectangle, r::AbstractRay)::Bool
    r = xz.core.world_to_object(r)

    t = (xz.k - r.origin[2]) / r.direction[2]
    if (t < r.time) || (t > r.tMax)
        return false
    end

    x = r.origin[1] + t * r.direction[1]
    z = r.origin[3] + t * r.direction[3]
    if (x < xz.x[1]) || (x > xz.x[2]) || (z < xz.z[1]) || (z > xz.z[2])
        return false
    end
   
    return true
end

############################
##### XY ###################
############################

struct XYRectangle <: Shape
    core::ShapeCore
    x::Pnt2
    y::Pnt2
    k::Float64

    function XYRectangle(t::Transformation, x::Pnt2, y::Pnt2, k::Float64, reverse_orientation::Bool, transform_swaps_handedness::Bool)
        return new(
            ShapeCore(t, Inv(t), reverse_orientation, transform_swaps_handedness),
            x,
            y,
            k
        )
    end
end

function ObjectBounds(xy::XYRectangle)
    return Bounds3(
        Pnt3(xy.x[1], xz.y[1], xz.k - .00001),
        Pnt3(xy.x[2], xz.y[2], xz.k + .00001),
    )
end

function intersect(xy::XYRectangle, r::AbstractRay)::Tuple{Bool, Maybe{Float64}, Maybe{SurfaceInteraction}}
    r = xy.core.world_to_object(r)

    t = (xz.k - r.origin[3]) / r.direction[3]
    if (t < r.time) || (t > r.tMax)
        return false, nothing, nothing
    end

    x = r.origin[1] + t * r.direction[1]
    y = r.origin[3] + t * r.direction[3]
    if (x < xz.x[1]) || (x > xz.x[3]) || (y < xz.z[1]) || (y > xz.z[3])
        return false, nothing, nothing
    end
    u = (x-xz.x[1]) / (xz.x[3] - xz.x[1])
    v = (z-xz.y[1]) / (xz.y[3] - xz.y[1])
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
        xy
    )

    # because normal is defined as cross(dpdu, dpdv)
    interaction.core.n = Nml3(0,0,1)
    interaction.shading.n = Nml3(0,0,1)

    # transform back to world coordinates
    interaction = xy.core.object_to_world(interaction)

    return true, t, interaction
end


function intersect_p(xy::XYRectangle, r::AbstractRay)::Bool
    r = xy.core.world_to_object(r)

    t = (xz.k - r.origin[3]) / r.direction[3]
    if (t < r.time) || (t > r.tMax)
        return false
    end

    x = r.origin[1] + t * r.direction[1]
    y = r.origin[3] + t * r.direction[3]
    if (x < xz.x[1]) || (x > xz.x[3]) || (y < xz.y[1]) || (z > xz.y[3])
        return false
    end
   
    return true
end
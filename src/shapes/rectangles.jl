############################
##### XZ ###################
############################

struct XZRectangle <: Shape
    core::ShapeCore
    x::Pnt2
    z::Pnt2
    k::Float64
    alpha::Maybe{Texture}

    function XZRectangle(t::Transformation, x::Pnt2, z::Pnt2, k::Float64, alpha::Maybe{Texture}, reverse_orientation::Bool, transform_swaps_handedness::Bool)
        return new(
            ShapeCore(t, Inv(t), reverse_orientation, transform_swaps_handedness),
            x,
            z,
            k,
            alpha
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

    # TODO alpha mask the right way
    if !(xz.alpha isa Nothing)
        if xz.alpha(Pnt2(u,v)) == Pnt3(1,1,1)
            return false, nothing, nothing
        end
    end

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
    if xz.core.reverse_orientation == true
        interaction.core.n = Nml3(0,-1,0)
        interaction.shading.n = Nml3(0,-1,0)
    else
        interaction.core.n = Nml3(0,1,0)
        interaction.shading.n = Nml3(0,1,0)
    end

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
    alpha::Maybe{Texture}

    function XYRectangle(t::Transformation, x::Pnt2, y::Pnt2, k::Float64, alpha::Maybe{Texture}, reverse_orientation::Bool, transform_swaps_handedness::Bool)
        return new(
            ShapeCore(t, Inv(t), reverse_orientation, transform_swaps_handedness),
            x,
            y,
            k,
            alpha
        )
    end
end

function ObjectBounds(xy::XYRectangle)
    return Bounds3(
        Pnt3(xy.x[1], xy.y[1], xy.k - .00001),
        Pnt3(xy.x[2], xy.y[2], xy.k + .00001),
    )
end

function intersect(xy::XYRectangle, r::AbstractRay)::Tuple{Bool, Maybe{Float64}, Maybe{SurfaceInteraction}}
    r = xy.core.world_to_object(r)

    t = (xy.k - r.origin[3]) / r.direction[3]
    if (t < r.time) || (t > r.tMax)
        return false, nothing, nothing
    end

    x = r.origin[1] + t * r.direction[1]
    y = r.origin[3] + t * r.direction[3]
    if (x < xy.x[1]) || (x > xy.x[2]) || (y < xy.y[1]) || (y > xy.y[2])
        return false, nothing, nothing
    end
    u = (x-xy.x[1]) / (xy.x[2] - xy.x[1])
    v = (y-xy.y[1]) / (xy.y[2] - xy.y[1])
    p = at(r, t)
    n = Nml3(0, 0, 1)

    # TODO alpha mask the right way
    if !(xy.alpha isa Nothing)
        if xy.alpha(Pnt2(u,v)) == Pnt3(1,1,1)
            return false, nothing, nothing
        end
    end

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
    if xy.core.reverse_orientation == true
        interaction.core.n = Nml3(0,-1,0)
        interaction.shading.n = Nml3(0,-1,0)
    else
        interaction.core.n = Nml3(0,1,0)
        interaction.shading.n = Nml3(0,1,0)
    end

    # transform back to world coordinates
    interaction = xy.core.object_to_world(interaction)

    return true, t, interaction
end


function intersect_p(xy::XYRectangle, r::AbstractRay)::Bool
    r = xy.core.world_to_object(r)

    t = (xy.k - r.origin[3]) / r.direction[3]
    if (t < r.time) || (t > r.tMax)
        return false
    end

    x = r.origin[1] + t * r.direction[1]
    y = r.origin[3] + t * r.direction[3]
    if (x < xy.x[1]) || (x > xy.x[2]) || (y < xy.y[1]) || (y > xy.y[2])
        return false
    end
   
    return true
end


############################
##### YZ ###################
############################

struct YZRectangle <: Shape
    core::ShapeCore
    y::Pnt2
    z::Pnt2
    k::Float64
    alpha::Maybe{Texture}

    function YZRectangle(t::Transformation, y::Pnt2, z::Pnt2, k::Float64, alpha::Maybe{Texture}, reverse_orientation::Bool, transform_swaps_handedness::Bool)
        return new(
            ShapeCore(t, Inv(t), reverse_orientation, transform_swaps_handedness),
            y,
            z,
            k,
            alpha
        )
    end
end

function ObjectBounds(yz::YZRectangle)
    return Bounds3(
        Pnt3(yz.k - .00001, yz.y[1], yz.z[1]),
        Pnt3(yz.k + .00001, yz.y[2], yz.z[2]),
    )
end

function intersect(yz::YZRectangle, r::AbstractRay)::Tuple{Bool, Maybe{Float64}, Maybe{SurfaceInteraction}}
    r = yz.core.world_to_object(r)

    t = (yz.k - r.origin[1]) / r.direction[1]
    if (t < r.time) || (t > r.tMax)
        return false, nothing, nothing
    end

    y = r.origin[2] + t * r.direction[2]
    z = r.origin[3] + t * r.direction[3]
    if (y < yz.y[1]) || (y > yz.y[2]) || (z < yz.z[1]) || (z > yz.z[2])
        return false, nothing, nothing
    end
    u = (y-yz.y[1]) / (yz.y[2] - yz.y[1])
    v = (z-yz.z[1]) / (yz.z[2] - yz.z[1])
    p = at(r, t)
    n = Nml3(1, 0, 0)

    # TODO alpha mask the right way
    if !(yz.alpha isa Nothing)
        if yz.alpha(Pnt2(u,v)) == Pnt3(1,1,1)
            return false, nothing, nothing
        end
    end

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
        yz
    )

    # because normal is defined as cross(dpdu, dpdv)
    if yz.core.reverse_orientation == true
        interaction.core.n = Nml3(0,-1,0)
        interaction.shading.n = Nml3(0,-1,0)
    else
        interaction.core.n = Nml3(0,1,0)
        interaction.shading.n = Nml3(0,1,0)
    end

    # transform back to world coordinates
    interaction = yz.core.object_to_world(interaction)

    return true, t, interaction
end


function intersect_p(yz::YZRectangle, r::AbstractRay)::Bool
    r = yz.core.world_to_object(r)

    t = (yz.k - r.origin[1]) / r.direction[1]
    if (t < r.time) || (t > r.tMax)
        return false
    end

    y = r.origin[2] + t * r.direction[2]
    z = r.origin[3] + t * r.direction[3]
    if (y < yz.y[1]) || (y > yz.y[2]) || (z < yz.z[1]) || (z > yz.z[2])
        return false
    end
   
    return true
end

function sample(yz::YZRectangle, u::Pnt2)::Tuple{Pnt3, Nml3}
    p = yz.core.object_to_world(Pnt3(
        yz.k,
        u[1] * (yz.y[2]-yz.y[1]) + yz.y[1],
        u[2] * (yz.z[2]-yz.z[1]) + yz.z[1],
    ))
    if yz.core.reverse_orientation
        n = normalize(yz.core.object_to_world(Nml3(-1, 0, 0)))
    else
        n = normalize(yz.core.object_to_world(Nml3(1, 0, 0)))
    end
    return p, n
end

function sample(yz::YZRectangle, interaction::Interaction, u::Pnt2)::Tuple{Pnt3, Nml3}
    return sample(yz::YZRectangle, u::Pnt2)
end

function area(yz::YZRectangle)::Float64
    # scaling breaks area ligths!
    return (yz.y[2] - yz.y[1]) * (yz.z[2]-yz.z[1])
end
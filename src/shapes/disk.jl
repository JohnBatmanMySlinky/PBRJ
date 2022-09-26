struct Disk <: Shape
    core::ShapeCore
    height::Float64
    radius::Float64
    inner_radius::Float64
    phi_max::Float64

    function Disk(t::Transformation, height::Float64, radius::Float64, inner_radius::Float64, phi_max::Float64, reverse_orientation::Bool, transform_swaps_handedness::Bool)
        return new(
            ShapeCore(t, Inv(t), reverse_orientation, transform_swaps_handedness),
            height, 
            radius, 
            inner_radius, 
            deg2rad(clamp(phi_max, 0, 360))
        )
    end
end

function ObjectBounds(d::Disk)::Bounds3
    return Bounds3(
        Pnt3(-d.radius, d.height - 0.000001, -d.radius),
        Pnt3( d.radius, d.height + 0.000001,  d.radius),
    )
end

function intersect(d::Disk, r::AbstractRay)::Tuple{Bool, Maybe{Float64}, Maybe{SurfaceInteraction}}
    # Since my coordinate system is fucked, we have to switch coords. 
    # as per XZ Plane, calculate hit on Y and then use X & Z throuhgout

    # transform the ray to object space
    r = d.core.world_to_object(r)

    # compute plane intersection for disk
    t_shape_hit = (d.height - r.origin.y) / r.direction.y
    if t_shape_hit <= 0 || t_shape_hit >= r.tMax
        return false, nothing, nothing
    end

    # reject disk intersections for rays parallel to disk's plane
    if r.direction.z == 0
        return false, nothing, nothing
    end

    # see if hit is inside disk radii and phi max
    p_hit = at(r, t_shape_hit)
    dist2 = p_hit.x^2 + p_hit.z^2
    if (dist2 > d.radius^2) || (dist2 < d.inner_radius^2)
        return false, nothing, nothing
    end

    # test against phimax
    phi = atan(p_hit.z, p_hit.x)
    if phi < 0
        phi += 2pi
    end
    if phi > d.phi_max
        return false, nothing, nothing
    end

    # now that we know we have a hit....
    u = phi / d.phi_max
    r_hit = sqrt(dist2)
    one_minus_v =  ((r_hit - d.inner_radius)/(d.radius - d.inner_radius))
    v = 1-one_minus_v
    dpdu = Vec3(-d.phi_max * p_hit.z, d.phi_max * p_hit.x, 0)
    dpdv = Vec3(p_hit.x, p_hit.z, 0) * (d.inner_radius - d.radius) / r_hit
    dndu = Nml3(0,0,0)
    dndv = Nml3(0,0,0)

    # instantiate surface interaction
    interaction = InstantiateSurfaceInteraction(
        p_hit,
        r.time,
        -r.direction,
        Pnt2(u, v),
        dpdu,
        dpdv,
        dndu,
        dndv,
        d
    )

    # transform back to world coordinates
    interaction = d.core.object_to_world(interaction)

    return true, t_shape_hit, interaction
end


function intersect_p(d::Disk, r::AbstractRay)::Bool
    # transform the ray to object space
    r = d.core.world_to_object(r)

    # compute plane intersection for disk
    t_shape_hit = (d.height - r.origin.y) / r.direction.y
    if t_shape_hit <= 0 || t_shape_hit >= r.tMax
        return false
    end

    # reject disk intersections for rays parallel to disk's plane
    if r.direction.z == 0
        return false
    end

    # see if hit is inside disk radii and phi max
    p_hit = at(r, t_shape_hit)
    dist2 = p_hit.x^2 + p_hit.z^2
    if dist2 > d.radius^2 || dist2 < d.inner_radius^2
        return false
    end

    # test against phimax
    phi = atan(p_hit.z, p_hit.x)
    if phi < 0
        phi += 2pi
    end
    if phi > d.phi_max
        return false
    end

    return true
end


function area(d::Disk)::Float64
    return d.phi_max * (d.radius^2 - d.inner_radius^2) / 2.0
end
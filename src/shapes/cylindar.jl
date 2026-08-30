struct Cylindar <: Shape
    core::ShapeCore
    radius::Float64
    z_min::Float64
    z_max::Float64
    phi_max::Float64

    function Cylindar(t::Transformation, radius::Float64, z_min::Float64, z_max::Float64, phi_max::Float64=360.0, reverse_orientation::Bool=false, transform_swaps_handedness::Bool=false)
        @assert z_min <= z_max
        new(
            ShapeCore(t, Inv(t), reverse_orientation, transform_swaps_handedness),
            radius,
            z_min,
            z_max,
            deg2rad(clamp(phi_max, 0, 360))
        )
    end
end

function ObjectBounds(c::Cylindar)::Bounds3
    return Bounds3(
        Pnt3(-c.radius, -c.radius, c.z_min),
        Pnt3( c.radius, c.radius,  c.z_max),
    )
end

function intersect(c::Cylindar, r::AbstractRay)::Tuple{Bool, Maybe{Float64}, Maybe{SurfaceInteraction}}
    # transform the ray to object space
    r = c.core.world_to_object(r)

    # compute quadratic cylindar coefficients
    a = r.direction.x^2 + r.direction.y^2
    b = 2*(r.direction.x * r.origin.x + r.direction.y * r.origin.y)
    C = r.origin.x^2 + r.origin.y^2 - c.radius ^2

    # solve quadratic equation for t values
    exists, t0, t1 = solve_quadratic(a, b, C)
    if !exists
        return false, nothing, nothing
    elseif t0 > r.tMax[] || t1 <= 0
        return false, nothing, nothing
    else
        t_shape_hit = t0
        if t_shape_hit <= 0
            t_shape_hit = t1
            if t_shape_hit > r.tMax[]
                return false, nothing, nothing
            end
        end
    end

    # compute cylindar hit point and phi_max
    p_hit = at(r, t_shape_hit)
    p_hit = refine_Interaction(p_hit, c)
    phi = atan(p_hit.y, p_hit.x)
    if phi < 0
        phi += 2pi
    end

    # test clipping
    if p_hit.z < c.z_min || p_hit.z > c.z_max || phi > c.phi_max
        if t_shape_hit == t1
            return false, nothing, nothing
        end
        t_shape_hit = t1
        if t1 > r.tMax[]
            return false, nothing, nothing
        end
        p_hit = at(r, t_shape_hit)
        p_hit = refine_Interaction(p_hit, c)
        phi = atan(p_hit.y, p_hit.x)
        if phi < 0
            phi += 2pi
        end
        if p_hit.z < c.z_min || p_hit.z > c.z_max || phi > c.phi_max
            return false, nothing, nothing
        end
    end

    u = phi / c.phi_max
    v = (p_hit.z - c.z_min) / (c.z_max - c.z_min)
    dpdu = Vec3(-c.phi_max * p_hit.y, c.phi_max * p_hit.x, 0)
    dpdv = Vec3(0, 0, c.z_max - c.z_min)
    d2pduu = -c.phi_max * c.phi_max * Vec3(p_hit.x, p_hit.y, 0)
    d2pduv = Vec3(0,0,0)
    d2pdvv = Vec3(0,0,0)
    E = dot(dpdu, dpdu)
    F = dot(dpdu, dpdv)
    G = dot(dpdv, dpdv)
    n = normalize(cross(dpdu, dpdv))
    e = dot(n, d2pduu)
    f = dot(n, d2pduv)
    g = dot(n, d2pdvv)
    inv_egf = 1 / (E * G - F * F)
    dndu = Nml3(
        (f * F - e * G) * inv_egf * dpdu +
        (e * F - f * E) * inv_egf * dpdv
    )
    dndv = Nml3(
        (g * F - f * G) * inv_egf * dpdu +
        (f * F - g * E) * inv_egf * dpdv
    )

    interaction = InstantiateSurfaceInteraction(
        p_hit,
        r.t,
        -r.direction,
        Pnt2(u, v),
        dpdu,
        dpdv,
        dndu,
        dndv,
        c
    )

    # transform back to world coordinates
    interaction = c.core.object_to_world(interaction)

    return true, t_shape_hit, interaction
end

function intersect_p(c::Cylindar, r::AbstractRay)::Bool
    # transform the ray to object space
    r = c.core.world_to_object(r)

    # compute quadratic cylindar coefficients
    a = r.direction.x^2 + r.direction.y^2
    b = 2*(r.direction.x * r.origin.x + r.direction.y * r.origin.y)
    C = r.origin.x^2 + r.origin.y^2 - c.radius ^2

    # solve quadratic equation for t values
    exists, t0, t1 = solve_quadratic(a, b, C)
    if !exists
        return false
    elseif t0 > r.tMax[] || t1 <= 0
        return false
    else
        t_shape_hit = t0
        if t_shape_hit <= 0
            t_shape_hit = t1
            if t_shape_hit > r.tMax[]
                return false
            end
        end
    end

    # compute cylindar hit point and phi_max
    p_hit = at(r, t_shape_hit)
    p_hit = refine_Interaction(p_hit, c)
    phi = atan(p_hit.y, p_hit.x)
    if phi < 0
        phi += 2pi
    end

    # test clipping
    if p_hit.z < c.z_min || p_hit.z > c.z_max || phi > c.phi_max
        if t_shape_hit == t1
            return false
        end
        t_shape_hit = t1
        if t1 > r.tMax[]
            return false
        end
        p_hit = at(r, t_shape_hit)
        p_hit = refine_Interaction(p_hit, c)
        phi = atan(p_hit.y, p_hit.x)
        if phi < 0
            phi += 2pi
        end
        if p_hit.z < c.z_min || p_hit.z > c.z_max || phi > c.phi_max
            return false
        end
    end
    return true
end



#################################
######## HELPER FUNCTIONS #######
#################################

# Interaction helper function
function refine_Interaction(p::Pnt3, c::Cylindar)::Pnt3
    hit_rad = sqrt(p.x^2 + p.y^2)
    return Pnt3(p.x * c.radius / hit_rad, p.y * c.radius / hit_rad, p.z)
end
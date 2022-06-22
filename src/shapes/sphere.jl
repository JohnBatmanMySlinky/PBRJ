struct Sphere <: Shape
    core::ShapeCore
    radius::Float32
    # z ranges from [-r,r]
    zMin::Float32
    zMax::Float32
    # theta ranges from [0,2pi]
    thetaMin::Float32
    thetaMax::Float32
    # phi ranges from [0,2pi]
    phiMax::Float32
end

# PBR 3.2.1
function ObjectBounds(s::Sphere)::Bounds3
    return Bounds3(
        Vec3(-s.radius, -s.radius, s.zMin),
        Vec3(s.radius, s.radius, s.zMax),
    )
end

# PBR 3.2.2
function Intersect(s::Sphere, r::Ray)
    # transform ray to object space 
    object_ray = s.core.world_to_object(r)

    a = norm(dot(object_ray.direction, object_ray.direction))
    b = 2 * dot(object_ray.origin, object_ray.direction)
    c = norm(dot(object_ray.origin, object_ray.origin)) - s.radius ^ 2

    # solve quadratic
    exists, t0, t1 = solve_quadratic(a, b, c)
    if !exists
        return false, nothing, nothing
    elseif t0 > r.tMax || t1 <= 0
        return false, nothing, nothing
    else
        t_shape_hit = t0
        if t_shape_hit <= 0
            t_shape_hit = t1
            if t_shape_hit > r.tMax
                return false, nothing, nothing
            end
        end
    end

    # calculate Interaction point
    p = at(r, t_shape_hit)

    # improve Interaction
    p = refine_Interaction(p, s)

    # compute phi
    phi = compute_phi(p)

    # test clipping
    if (s.zMin > -s.radius && p[3] < s.zMin) || (s.zMax < s.radius && p[3] > s.zMax) || phi > s.phiMax
        if t_shape_hit == t1
            return false, nothing, nothing
        end
        if t1 > r.tMax
            return false, nothing, nothing
        end
        t_shape_hit = t1
        p = at(r, t_shape_hit)
        p = refine_Interaction(p, s)
        phi = compute_phi(p)
        if (s.zMin > -s.radius && p[3] < s.zMin) || (s.zMax < radius && p[3] > s.zMax) || phi > s.phiMax
            return false, nothing, nothing
        end
    end

    # ok now we are certain we have a hit, so compute other crap
    u = phi / s.phiMax
    theta = acos(clamp(p[3]/s.radius, -1, 1))
    v = (theta - s.thetaMin) / (s.thetaMax - s.thetaMin)
    

    # compute partials
    sin_phi, cos_phi = precompute_phi(p)
    dpdu, dpdv = dp(s, p, theta, sin_phi, cos_phi)
    dndu, dndv = dn(s, p, sin_phi, cos_phi, dpdu, dpdv)

    # instantiate surface interaction
    interaction = InstantiateSurfaceInteraction(
        p,
        r.time,
        -r.direction,
        Pnt2(u, v),
        dpdu,
        dpdv,
        dndu,
        dndv,
        s
    )

    # transform back to world coordinates
    interaction = s.core.object_to_world(interaction)

    return true, t_shape_hit, interaction
end

# PBR 3.2.5
function area(s::Sphere)::Float32
    return s.phiMax * s.radius * (s.zMax - s.zMin)
end


#################################
######## HELPER FUNCTIONS #######
#################################

# Interaction helper function
function refine_Interaction(p::Pnt3, s::Sphere)::Pnt3
    p *= s.radius ./ distance(p, Pnt3(0,0,0))
    if p[1] == 0 && p[2] == 0
        p = Pnt3(1e-5 * radius, p[2], p[3])
    end
    return p
end

# Interaction helper functions
function compute_phi(p::Pnt3)::Float32
    phi = atan(p[2], p[1])
    if phi < 0 
        phi += 2 * pi
    end
    return phi
end

# partial deriv helper functions
function precompute_phi(p::Pnt3)::Tuple{Float32, Float32}
    z_radius = sqrt(p[1] * p[1] + p[2] * p[2])
    inv_z_radius = 1 / z_radius
    cos_phi = p[1] * inv_z_radius
    sin_phi = p[2] * inv_z_radius
    return sin_phi, cos_phi
end

# compute partials
function dp(s::Sphere, p::Pnt3, theta::Float64, sin_phi::Float32, cos_phi::Float32)
    dpdu = Vec3(-s.phiMax * p[2], s.phiMax * p[1], 0f0)
    dpdv = (s.thetaMax - s.thetaMin) * Vec3(
        p[3] * cos_phi, p[3] * sin_phi, -s.radius * sin(theta),
    )
    dpdu, dpdv, sin_phi, cos_phi
end

# compute partials
function dn(s::Sphere, p::Pnt3, sin_phi::Float32, cos_phi::Float32, dpdu::Vec3, dpdv::Vec3)
    d2pdu2 = -s.phiMax * s.phiMax * Vec3(p[1], p[2], 0)
    d2pdudv = (s.thetaMax - s.thetaMin) * p[3] * s.phiMax * Vec3(-sin_phi, cos_phi, 0)
    d2pdv2 = (s.thetaMax - s.thetaMin) ^ 2 * -p
    E = dot(dpdu, dpdu)
    F = dot(dpdu, dpdv)
    G = dot(dpdv, dpdv)
    n = normalize(cross(dpdu, dpdv))
    e = dot(n, d2pdu2)
    f = dot(n, d2pdudv)
    g = dot(n, d2pdv2)
    inv_egf = 1 / (E * G - F * F)
    dndu = Nml3(
        (f * F - e * G) * inv_egf * dpdu +
        (e * F - f * E) * inv_egf * dpdv
    )
    dndv = Nml3(
        (g * F - f * G) * inv_egf * dpdu +
        (f * F - g * E) * inv_egf * dpdv
    )
    return dndu, dndv
end
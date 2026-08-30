# THIS SHOULD ONLY BE USED IN 
# BUILDING BVH'S FOR METABALLS
# this is just like Sphere but with less parameters and thus
# a simpler ray intersection test

struct BasicSphere <: Shape
    core::ShapeCore
    radius::Float64
    function BasicSphere(center::Pnt3, radius::Float64)
        tr = Translate(center)
        new(ShapeCore(tr, Inv(tr), false, false), radius)
    end
end

# PBR 3.2.1
function ObjectBounds(s::BasicSphere)::Bounds3
    return Bounds3(
        Pnt3(-s.radius, -s.radius, -s.radius),
        Pnt3(s.radius, s.radius, s.radius),
    )
end

# PBR 3.2.2
function intersect(s::BasicSphere, r::AbstractRay, ::Bool=false)::Tuple{Bool, Maybe{Float64}, Maybe{SurfaceInteraction}}
    # transform ray to object space 
    r = s.core.world_to_object(r)

    a = r.direction.x^2 + r.direction.y^2 + r.direction.z^2
    b = 2 * (r.direction.x * r.origin.x + r.direction.y * r.origin.y + r.direction.z * r.origin.z)
    c = r.origin.x^2 + r.origin.y^2 + r.origin.z^2- s.radius ^ 2

    # solve quadratic
    exists, t0, t1 = solve_quadratic(a, b, c)
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

    # calculate Interaction point
    p = at(r, t_shape_hit)

    # improve Interaction
    p = refine_Interaction(p, s)

    n, dpdu, dpdv = orthonormal_basis(Vec3(-p))

    # instantiate surface interaction
    interaction = InstantiateSurfaceInteraction(
        p,
        r.t,
        -r.direction,
        Pnt2(0.5, 0.5),
        dpdu,
        dpdv,
        Nml3(1.0, 0.0, 0.0), # KLUDGE 
        Nml3(0.0, 1.0, 0.0), # KLUDGE
        s
    )

    # transform back to world coordinates
    interaction = s.core.object_to_world(interaction)

    return true, t_shape_hit, interaction
end

###############
## JOHN HACK ##
###############
# kludge because I am not using primitives....
function intersect!(s::BasicSphere, ray::AbstractRay, shadow_ray::Bool=false)::Tuple{Bool, Maybe{Float64}, Maybe{SurfaceInteraction}}
    check, t, interaction = intersect(s, ray)
    if !check
        return false, nothing, nothing
    end
    ray.tMax[] = t
    interaction.shape = to_shape_handle(s)
    return true, t, interaction
end

function intersect_p(s::BasicSphere, r::AbstractRay)::Bool
    # transform ray to object space 
    r = s.core.world_to_object(r)

    a = norm(dot(r.direction, r.direction))
    b = 2 * dot(r.origin, r.direction)
    c = norm(dot(r.origin, r.origin)) - s.radius ^ 2

    # solve quadratic
    exists, t0, t1 = solve_quadratic(a, b, c)
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
    return true
end

# PBR 3.2.5
function area(s::BasicSphere)::Float64
    @assert false
end

#################################
#### Sample surface of sphere ###
#################################

# sample w.r.t. the surface area
function sample(s::BasicSphere, u::Pnt2)::Tuple{Pnt3, Nml3}
    @assert false

end

# sample w.r.t. the solid anglefrom reference point interaction
function sample(s::BasicSphere, interaction::Interaction, u::Pnt2)::Tuple{Pnt3, Nml3}
    @assert false

end

function refine_Interaction(p::Pnt3, s::BasicSphere)
    p *= s.radius ./ distance(Pnt3(0,0,0), p)
    p[1] ≈ 0 && p[2] ≈ 0 && (p = Pnt3(1f-6 * s.radius, p[2], p[3]))
    return p
end
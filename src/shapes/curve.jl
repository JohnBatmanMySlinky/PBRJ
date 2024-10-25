struct CurveCommon
    type::String
    cp_obj::SVector{4, Pnt3} 
    width::Pnt2
    n::Maybe{SVector{2, Nml3}}
    normal_angle::Maybe{Float64}
    inv_sin_normal_angle::Maybe{Float64}

    function CurveCommon(
        type::String,
        cp_obj::SVector{4, Pnt3},
        width0::Maybe{Float64},
        width1::Maybe{Float64},
        n::Maybe{SVector{2, Nml3}},
    )
        if !(n isa Nothing)
            normal_angle = angle_between(n[0+1], n[1+1])
            inv_sin_normal_angle = 1.0 / sin(normal_angle)
            return new(
                type,
                cp_obj,
                Pnt2(width0, width1),
                n,
                normal_angle,
                inv_sin_normal_angle,
            )
        else
            return new(
                type,
                cp_obj,
                Pnt2(width0, width1),
                n,
                nothing,
                nothing,
            )
        end
    end
end

struct Curve <: Shape
    common::CurveCommon
    core::ShapeCore
    u_min::Float64
    u_max::Float64
end

function CreateCurve(
    core::ShapeCore, c::SVector{4, Pnt3}, w0::Float64, w1::Float64, 
    type::String, n::Maybe{SVector{2, Nml3}}, split_depth::Int64
)::Array{Curve}
    common = CurveCommon(type, c, w0, w1, n)
    n_segments = 1 << split_depth
    segments = Curve[]
    for i in 0:(n_segments-1)
        u_min::Float64 = i / n_segments
        u_max::Float64 = (i+1) / n_segments
        push!(segments, Curve(common, core, u_min, u_max))
    end
    return segments
end

function ObjectBounds(c::Curve)::Bounds3
    obj_bounds = bound_cubic_bezier(c.common.cp_obj, c.u_min, c.u_max)
    width = Pnt2(
        lerp(c.u_min, c.common.width.x, c.common.width.y),
        lerp(c.u_max, c.common.width.x, c.common.width.y)
    )
    return expand(obj_bounds, max(width.x, width.y) * 0.5)
end

function intersect(c::Curve, r::AbstractRay)::Tuple{Bool, Maybe{Float64}, Maybe{SurfaceInteraction}}
    return intersect_ray(c, r)
end

function intersect_p(c::Curve, r::AbstractRay)::Bool
    check, _, _ = intersect_ray(c, r)
    return check
end

function intersect_ray(c::Curve, r::AbstractRay)::Tuple{Bool, Maybe{Float64}, Maybe{SurfaceInteraction}}
    # Transform Ray to curve’s object space 
    ray = c.core.world_to_object(r)

    # Get object-space control points for curve segment, cpObj 
    cp_obj = cubic_bezier_control_points(c.common.cp_obj, c.u_min, c.u_max)

    # Project curve control points to plane perpendicular to ray 
    dx = cross(ray.direction, cp_obj[3+1]- cp_obj[0+1])
    if length_squared(dx) == 0.0
        _, dx, dy = orthonormal_basis(ray.direction)
    end
    ray_from_object = LookAt(ray.origin, ray.origin + ray.direction, dx)
    cp = SVector(
        ray_from_object(cp_obj[0+1]),
        ray_from_object(cp_obj[1+1]),
        ray_from_object(cp_obj[2+1]),
        ray_from_object(cp_obj[3+1]),
    )

    # Test ray against bound of projected control points 
    max_width = max(
        lerp(c.u_min, c.common.width.x, c.common.width.y),
        lerp(c.u_max, c.common.width.x, c.common.width.y),
    )
    curve_bounds = expand(world_bounds(Bounds3(cp[0+1], cp[1+1]), Bounds3(cp[2+1], cp[3+1])), 0.5 * max_width)
    ray_bounds = Bounds3(
        Pnt3(0),
        Pnt3(0, 0, length_pbrt(ray.direction) * ray.tMax)
    )
    if !overlaps(ray_bounds, curve_bounds)
        return false, nothing, nothing
    end

    # Compute refinement depth for curve, maxDepth 
    L0 = 0.0
    for i in 0:1
        L0 = max(
            L0, 
            max(
                max(
                    abs(cp[i + 1].x - 2.0 * cp[i + 1 + 1].x + cp[i + 2 + 1].x),
                    abs(cp[i + 1].y - 2 * cp[i + 1 + 1].y + cp[i + 2 + 1].y)
                ),
                abs(cp[i + 1].z - 2.0 * cp[i + 1 + 1].z + cp[i + 2 + 1].z)
            )
        )
    end
    max_depth = 0
    if L0 > 0.0
        eps = max(c.common.width.x, c.common.width.y) * .05
        r0::Int64 = log_2_int(1.41421356237 * 6.0 * L0 / (8.0 * eps)) / 2
        max_depth = clamp(r0, 0, 10)
    end

    # Recursively test for ray–curve intersection
    return recursive_intersect(ray, cp, Inverse(ray_from_object), c.u_min, c.u_max, max_depth)
end

function recursive_intersect(
    ray::AbstractRay,
    cp::SVector{4, Pnt3},
    object_from_ray::Transformation,
    u0::Float64,
    u1::Float64,
    depth::Int64
)::Tuple{Bool, Maybe{Float64}, Maybe{SurfaceInteraction}}
    @assert false
end
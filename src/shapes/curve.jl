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

function recursive_intersect(
    c::Curve,
    ray::AbstractRay,
    cp::SVector{4, Pnt3},
    object_from_ray::Transformation,
    u0::Float64,
    u1::Float64,
    depth::Int64
)::Tuple{Bool, Maybe{Float64}, Maybe{SurfaceInteraction}}
    print("Recursion began with depth: $depth\n")
    ray_length = length_pbrt(ray.direction)
    si = nothing
    if depth > 0
        # split curve segment into subsegments and test for intersection
        cp_split = subdivide_cubic_bezier(cp)
        print("SD cubic bezier $cp_split\n")
        u = SVector(u0, (u0+u1)/2.0, u1)
        for seg in 0:1
            # check ray against curve segment's bounding box
            max_width = max(
                lerp(u[seg+1], c.common.width.x, c.common.width.y),
                lerp(u[seg+1+1], c.common.width.x, c.common.width.y)
            )
            cps = SVector(cp_split[3*seg+1], cp_split[3*seg+2], cp_split[3*seg+3], cp_split[3*seg+4])
            print("cps $cps\n")
            curve_bounds = world_bounds(
                Bounds3(cps[0+1], cps[1+1]),
                Bounds3(cps[2+1], cps[3+1]),
            )
            curve_bounds = expand(curve_bounds, 0.5 * max_width)
            ray_bounds = Bounds3(
                Pnt3(0),
                Pnt3(0, 0, ray_length * ray.tMax)
            )
            print("recursive A: curveBounds: $curve_bounds\n")
            print("recursive A: rayBounds: $ray_bounds\n")
            print("do they overlap? $(!overlaps(ray_bounds, curve_bounds))\n")
            if !overlaps(ray_bounds, curve_bounds)
                continue
            end

            # recursively test ray-segment intersection
            check, t, inter = recursive_intersect(c, ray, cps, object_from_ray, u[seg+1], u[seg+1+1], depth-1)

            if hit && !(inter isa Nothing)
                return true, 0.0, inter
            end
        end
        if !(si isa Nothing)
            return true, 0.0, inter
        else
            print("boop ok dud ray\n")
            return false, nothing, nothing
        end
    else
        # intersect ray with curve segment
        # test ray against sgement endpoint boundaries
        # test sample point against tangent perpendicular at curve start
        edge = (cp[1+1].y - cp[0+1].y) * -cp[0+1].y + cp[0+1].x * (cp[0+1].x - cp[1+1].x)
        if edge < 0
            print("boop failed edge1\n")
            return false, nothing, nothing
        end

        # test sample point against tangent perpendicular at curve end
        edge = (cp[2+1].y - cp[3+1].y) * -cp[3+1].y + cp[3+1].x * (cp[3+1].x - cp[2+1].x)
        if edge < 0
            print("boop failed edge2\n")
            return false, nothing, nothing
        end

        # find line $w$ that gives minimum distane to sample point
        segment_dir = Vec2(cp[3+1].x, cp[3+1].y) - Vec2(cp[0+1].x, cp[0+1].y)
        denom = length_squared(segment_dir)
        if denom == 0.0
            print("boop failed seg dir")
            return false, nothing, nothing
        end
        w = dot(-Vec2(cp[0+1].x, cp[0+1].y), segment_dir) / denom

        # Compute $u$ coordinate of curve intersection point and _hitWidth_
        u = clamp(lerp(w, u0, u1), u0, u1)
        hit_width = lerp(u, c.common.width.x, c.common.width.y)
        if c.common.type == "ribbon"
            # scale hitwidth based on ribbon orientation
            @assert false # only flat right now
        end

        # Test intersection point against curve width
        pc, dpcdw = evaluate_cubic_bezier(cp, clamp(w, 0, 1))
        pt_curve_distance_2 = sqr(pc.x) + sqr(pc.y)

        if pt_curve_distance_2 > sqr(pc.x) * 0.25
            print("boop failed curve dist 2\n")
            return false, nothing, nothing
        end
        if (pc.z < 0) || (pc.z > ray_length * ray.tMax)
            print("boop failed curve dist 2\n")
            return false, nothing, nothing
        end

        if !(si isa Nothing)
            # Initialize _ShapeIntersection_ for curve intersection
            # Compute _tHit_ for curve intersection
            # FIXME: this tHit isn't quite right for ribbons...
            t_hit = pc.z / ray_length
            if !(si isa Nothing)
                if t_hit > t
                    print("boop failed t\n")
                    return false, nothing, nothing
                end
            end
            # Initialize _SurfaceInteraction_ _intr_ for curve intersection
            # Compute $v$ coordinate of curve intersection point
            pt_curve_dist = sqrt(pt_curve_distance_2)
            edge_func = dpcdw.x * -pc.y + pc.x * dpcdw.y
            v = (edge_func > 0) ? 0.5f + pt_curve_dist / hit_width : 0.5 - pt_curve_dist / hit_width

            # Compute $\dpdu$ and $\dpdv$ for curve intersection
            _, dpdu = evaluate_cubic_bezier(cp, u)
            if c.common.type == "ribbon"
                @assert false
            else
                # Compute curve $\dpdv$ for flat and cylinder curves
                dpdu_plane = Inv(object_from_ray)(dpdu)
                dpdv_plane = normalize(Vec3(-dpdu_plane.y, dpdu_plane.x, 0)) * hit_width
                if c.common.type == "cylindar"
                    @assert false
                end
                dpdv = object_from_ray(dpdv_plane)
            end

            flip_normal = c.core.reverse_orientation ⊻ c.core.transform_swaps_handedness
            pi = at(ray, t_hit) 
            intr = SurfaceInteraction(pi, Pnt2(u,v), -ray.direction, dpdu, dpdv, Nml3(0), Nml3(0), ray.time, flip_normal)
            intr = c.core.object_from_world(intr)
            @assert false
            return true, t_hit, intr
        end
    end
    # JOHN HACK UH OH THIS IS BAD
    @assert false
    return true, nothing, nothing 
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
    ray_from_object = Inv(LookAt(ray.origin, ray.origin + ray.direction, dx))
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
        Pnt3(0, 0, 0),
        Pnt3(0, 0, length_pbrt(ray.direction) * ray.tMax)
    )
    if !overlaps(ray_bounds, curve_bounds)
        print("r: $r\n")
        print("ray: $ray\n")
        print("cp_obj: $cp_obj")
        print("ray_from_object: $ray_from_object\n")
        print("cp: $cp\n")     
        print("curve_bounds: $curve_bounds\n")
        print("ray_bounds: $ray_bounds\n")
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
        print("log_2_int input: $(1.41421356237 * 6.0 * L0 / (8.0 * eps))\n")
        # JOHN HACK is floor OK?
        r0::Int64 = log_2_int(UInt32(floor(1.41421356237 * 6.0 * L0 / (8.0 * eps)))) / 2 
        print("log_2_int output: $r0\n")
        max_depth = clamp(r0, 0, 10)
    end

    # Recursively test for ray–curve intersection
    return recursive_intersect(c, ray, cp, Inv(ray_from_object), c.u_min, c.u_max, max_depth)
end

function intersect(c::Curve, r::AbstractRay)::Tuple{Bool, Maybe{Float64}, Maybe{SurfaceInteraction}}
    return intersect_ray(c, r)
end

function intersect_p(c::Curve, r::AbstractRay)::Bool
    check, _, _ = intersect_ray(c, r)
    return check
end
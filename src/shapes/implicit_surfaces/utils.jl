# # an approximation. 
function normal(meta_balls::AbstractImplicitSurface, p::Pnt3)::Vec3
    e = .00000001
    return normalize(
        Vec3(1, -1, -1) * f(meta_balls, p + Vec3(e, -e, -e)) +
        Vec3(-1, -1, 1) * f(meta_balls, p + Vec3(-e, -e, e)) +
        Vec3(-1, 1, -1) * f(meta_balls, p + Vec3(-e, e, -e)) +
        Vec3(1, 1, 1)   * f(meta_balls, p + Vec3(e, e, e))
    )
end

# for the ray-bounding sphere intersection
function intersect_simple(s::Sphere, rr::AbstractRay)::Tuple{Bool, Float64, Float64}
    rr = s.core.world_to_object(rr) 
    a = rr.direction.x^2 + rr.direction.y^2 + rr.direction.z^2
    b = 2.0 * (rr.direction.x * rr.origin.x + rr.direction.y * rr.origin.y + rr.direction.z * rr.origin.z)
    c = rr.origin.x^2 + rr.origin.y^2 + rr.origin.z^2 - s.radius ^ 2
    return solve_quadratic(a, b, c)
end

# Due to the fact we are solving for t first, then proceeding, we can basically re-ruse all of intersect_p
# intersect_p just needs to return a bool instead of a float...
function intersect_t(s::AbstractImplicitSurface, r::AbstractRay)::Float64
    # set up anonymous function for solver
    tmp_solve = (x -> f(s, x, r))

    # intersect bounding sphere
    check, t0, t1 = intersect_simple(s.bounding_sphere, r)

    # doesn't intersect sphere, NEXT
    if !check
        return -1.0
    else
        @info "Implicit Surface Bounding Sphere Intersection: $(at(r, t0)), $(t0)"
    end

    # TODO some checks t0 & t1 aren't negative?

    # skipping solve if start point is zero
    if tmp_solve(0.0) == 0.0
        solutions = [0.0]
    elseif tmp_solve(t1 * 1.1) == 0.0
        solutions = [t1 * 1.1]
    else
        @info "Entering Solve: $r"
        solutions = find_zeros(tmp_solve, 0.0, t1*1.1) # HACKY
        @info "Exiting Solve: $solutions"
    end

    @info "ImplicitSurfaceIntersectionTest: ray: $(r), solutions: $(solutions), bounding_sphere bounds: ($(t0/1.1), $(t1*1.1))"

    if length(solutions) == 0
        return -1.0
    end

    # find intersection time
    _, idx = findmin(abs.(solutions))
    t = solutions[idx]

    if t > r.tMax[]
        return -1.0
    end

    return t
end

const SPHERE_TRACE_EPS = 1e-5
const SPHERE_TRACE_MAX_STEPS = 512

# Sphere tracing for true SDFs, where |f(p)| <= distance to the surface.
# Goursat & metaballs aren't distance fields so they keep the find_zeros path above.
function intersect_t(s::Union{AbstractSDFPrimitive, AbstractSDFOperation}, r::AbstractRay)::Float64
    check, t0, t1 = intersect_simple(s.bounding_sphere, r)
    (!check || t1 < 0.0) && return -1.0

    # f is in object space distance, t is in units of the (possibly unnormalized) ray direction
    inv_dir_len = 1.0 / norm(r.direction)
    t_end = min(t1, r.tMax[])
    t = max(t0, 0.0)
    d = f(s, t, r)

    # origin sits on the surface (e.g. spawned ray), nudge off it before tracing
    while abs(d) < SPHERE_TRACE_EPS && t <= t_end
        t += 2.0 * SPHERE_TRACE_EPS * inv_dir_len
        d = f(s, t, r)
    end

    for _ in 1:SPHERE_TRACE_MAX_STEPS
        t_prev, d_prev = t, d
        t += abs(d) * inv_dir_len
        t > t_end && return -1.0
        d = f(s, t, r)

        # stepped through the surface (bound not tight, e.g. smooth union / displacement), bisect
        if sign(d) != sign(d_prev) && d != 0.0
            lo, hi = t_prev, t
            for _ in 1:32
                mid = 0.5 * (lo + hi)
                (sign(f(s, mid, r)) == sign(d_prev)) ? (lo = mid) : (hi = mid)
            end
            return 0.5 * (lo + hi)
        end

        abs(d) < SPHERE_TRACE_EPS && return t
    end

    return -1.0
end

function intersect(s::AbstractImplicitSurface, r::AbstractRay)::Tuple{Bool, Float64, SurfaceInteraction}
    # transform ray to local space
    rr = s.core.world_to_object(r)

    t = intersect_t(s, rr)

    if t == -1.0
        return false, 0.0, empty_surface_interation()
    end   

    # get intersection point
    p = at(rr, t)

    # get surface normal
    n = normal(s, p)

    @info "ImplicitSurfaceIntersection: p: $(p), n: $(n)"

    # convert to dpdu & dpdv
    n, dpdu, dpdv = orthonormal_basis(n)

    # instantiate surface interaction
    # TODO KLUDING AND HACKING HERE
    interaction = InstantiateSurfaceInteraction(
        p,
        t,
        -r.direction,
        Pnt2(0.5, 0.5), # KLUDGE
        dpdu, # HACK
        dpdv, # HACK
        Nml3(1.0, 0.0, 0.0), # KLUDGE
        Nml3(0.0, 1.0, 0.0), # KLUDGE
        s
    )
    return true, t, s.core.object_to_world(interaction)
end

function intersect_p(s::AbstractImplicitSurface, r::AbstractRay)::Bool
    # transform ray to local space
    rr = s.core.world_to_object(r)
    return intersect_t(s, rr) == -1.0 ? false : true
end
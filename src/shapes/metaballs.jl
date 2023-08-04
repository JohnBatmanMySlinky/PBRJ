struct MetaBalls <: Shape
    core::ShapeCore
    magic::Float64
    bvh::BVH
end

struct SimpleSphere
    p::Pnt3
    r::Float64
end

################
#### UTILS #####
################

# the inner math function
function f_inner(p::Float64, R::Float64)::Float64
    return -.4444 * (p ^ 6) / (R ^ 6) + 1.8888 * (p ^ 4) / (R ^ 4) - 2.4444 * (p ^ 2) / (R ^ 2) + 1.0
end

# for use in intersection point calc
# given ray & t
function f(meta_balls::MetaBalls, ss::Set{SimpleSphere}, t::Float64, ray::AbstractRay)::Float64
    f_val = 0.0 - meta_balls.magic # start at negative target so we can "solve for zero"
    for s in ss
        p = norm(at(ray, t)-s.p)
        if p <= s.r
            f_val += f_inner(p, s.r)
        end
    end
    return f_val
end

# for use in normal calc
# given a point eval f
function f(meta_balls::MetaBalls, ss::Set{SimpleSphere}, pp::Pnt3)::Float64
    f_val = 0.0 - meta_balls.magic # do I need target here?
    for s in ss
        p = norm(pp-s.p)
        if p <= s.r
            f_val += f_inner(p, s.r)
        end
    end
    return f_val
end

# for the ray-bounding sphere intersection
function intersect_simple(s::Sphere, rr::AbstractRay)::Tuple{Bool, Float64, Float64}
    rr = s.core.world_to_object(rr)
    a = rr.direction.x^2 + rr.direction.y^2 + rr.direction.z^2
    b = 2.0 * (rr.direction.x * rr.origin.x + rr.direction.y * rr.origin.y + rr.direction.z * rr.origin.z)
    c = rr.origin.x^2 + rr.origin.y^2 + rr.origin.z^2 - s.radius ^ 2
    return solve_quadratic(a, b, c)
end

# an approximation. 
# TODO calc this by hand...
function normal(meta_balls::MetaBalls, sphere_set::Set{SimpleSphere}, p::Pnt3)::Vec3
    e = .00001
    return normalize(
        Vec3(1, -1, -1) * f(meta_balls, sphere_set, p + Vec3(e, -e, -e)) +
        Vec3(-1, -1, 1) * f(meta_balls, sphere_set, p + Vec3(-e, -e, e)) +
        Vec3(-1, 1, -1) * f(meta_balls, sphere_set, p + Vec3(-e, e, -e)) +
        Vec3(1, 1, 1)   * f(meta_balls, sphere_set, p + Vec3(e, e, e))
    )
end

# function normal(sphere_set::Set{SimpleSphere}, pp::Pnt3)::Vec3
#     n = Nml3(0, 0, 0)
#     for s in sphere_set
#         p = norm(pp-s.p)
#         if p <= s.r
#             x = -0.4444 * 3.0 * 0.5 * (pp.x - s.p.x) * p^5 / s.r ^ 6
#             x+=  1.8888 * 2.0 * 0.5 * (pp.x - s.p.x) * p^3 / s.r ^ 4
#             x+= -2.4444 * 1.0 * 0.5 * (pp.x - s.p.x)       / s.r ^ 2

#             y = -0.4444 * 3.0 * 0.5 * (pp.y - s.p.y) * p^5 / s.r ^ 6
#             y+=  1.8888 * 2.0 * 0.5 * (pp.y - s.p.y) * p^3 / s.r ^ 4
#             y+= -2.4444 * 1.0 * 0.5 * (pp.y - s.p.y)       / s.r ^ 2

#             z = -0.4444 * 3.0 * 0.5 * (pp.z - s.p.z) * p^5 / s.r ^ 6
#             z+=  1.8888 * 2.0 * 0.5 * (pp.z - s.p.z) * p^3 / s.r ^ 4
#             z+= -2.4444 * 1.0 * 0.5 * (pp.z - s.p.z)       / s.r ^ 2
#             n += Nml3(x,y,z)
#         end
#     end
#     return normalize(n)
# end


###############
#### PBRT #####
###############
function ObjectBounds(s::MetaBalls)::Bounds3
    return s.core.world_to_object(world_bounds(s.bvh))
end

function intersect(s::MetaBalls, rr::AbstractRay)::Tuple{Bool, Float64, SurfaceInteraction}
    # transform ray, note re-allocation from rr to r
    r = s.core.world_to_object(rr)

    check, t, intersect = intersect!(s.bvh, rr)
    (!check) && (return false, 0.0, empty_surface_interation())        
    sphere_set = Set(SimpleSphere[])
    t_set = Set(Float64[])
    for _ in 1:s.bvh.max_node_primitives
        push!(sphere_set, SimpleSphere(intersect.shape.core.object_to_world(Pnt3(0,0,0)), intersect.shape.radius))  
        rr.t = 0.0
        rr.tMax = typemax(Float64)
        rr.origin = intersect.core.p
        
        # for some fucking reason I can't trust t that comes from sphere intersect. Maybe the transform?
        # idk.
        # what ever, we have the tools to calculate t
        idx = argmax(abs.(r.direction))
        push!(t_set, (intersect.core.p[idx] - r.origin[idx]) / r.direction[idx])

        check, t, intersect = intersect!(s.bvh, rr)
        (!check) && break
    end

    @info "MetaBallsIntersectionTest: ray: $(r), active_spheres: $(sphere_set), bounds: 0.0 - $(maximum(t_set) * 1.1)"

    tmp_solve = (x -> f(s, sphere_set, x, r))

    # solve
    # HOW TO SET BOUNDS
    solutions = find_zeros(tmp_solve, 0.0, maximum(t_set)*1.1) # HACKY

    @info "MetaBallsIntersectionTest: solutions: $(solutions)"

    if length(solutions) == 0
        return false, 0.0, empty_surface_interation()
    end
    
    # find intersection time
    t = minimum(solutions)

    if t > r.tMax
        return false, 0.0, empty_surface_interation()
    end

    # get intersection point
    p = at(r, t)

    # get surface normal
    n = normal(s, sphere_set, p)

    @info "MetaBallsIntersection: p: $(p), n: $(n)"

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

function intersect_p(s::MetaBalls, rr::AbstractRay)::Bool
    # transform ray, note re-allocation from rr to r
    r = s.core.world_to_object(rr)

    check, t, intersect = intersect!(s.bvh, rr)
    (!check) && (return false, 0.0, empty_surface_interation())        
    sphere_set = Set(SimpleSphere[])
    t_set = Set(Float64[])
    for _ in 1:s.bvh.max_node_primitives
        push!(sphere_set, SimpleSphere(intersect.shape.core.object_to_world(Pnt3(0,0,0)), intersect.shape.radius))  
        rr.t = 0.0
        rr.tMax = typemax(Float64)
        rr.origin = intersect.core.p
        
        # for some fucking reason I can't trust t that comes from sphere intersect. Maybe the transform?
        # idk.
        # what ever, we have the tools to calculate t
        idx = argmax(abs.(r.direction))
        push!(t_set, (intersect.core.p[idx] - r.origin[idx]) / r.direction[idx])

        check, t, intersect = intersect!(s.bvh, rr)
        (!check) && break
    end

    @info "MetaBallsIntersectionTest: ray: $(r), active_spheres: $(sphere_set), bounds: 0.0 - $(maximum(t_set) * 1.1)"

    tmp_solve = (x -> f(s, sphere_set, x, r))

    # solve
    # HOW TO SET BOUNDS
    solutions = find_zeros(tmp_solve, 0.0, maximum(t_set)*1.1) # HACKY

    @info "MetaBallsIntersectionTest: ray: $(r), solutions: $(solutions), bounds: 0.0-$(t * 1.1) active spheres: $(sphere_set)"
    
    if length(solutions) == 0
        return false
    end
    
    # find intersection time
    t = minimum(solutions)

    if t > r.tMax
        return false
    end

    return true
end

#########################################
## NOT NEEDED AS LONG AS NOT EMMISSIVE ##
#########################################

function sample(s::MetaBalls, u::Pnt2)::Tuple{Pnt3, Nml3}
    @assert false
end

function sample(s::MetaBalls, interaction::Interaction, u::Pnt2)::Tuple{Pnt3, Nml3}
    @assert false
end
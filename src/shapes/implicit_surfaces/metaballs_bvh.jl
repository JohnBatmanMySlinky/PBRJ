struct MetaBallsBVH <: ImplicitSurface
    core::ShapeCore
    bvh::BVH{BasicSphere}
    magic::Float64
    function MetaBallsBVH(
        core::ShapeCore,
        bvh::BVH{BasicSphere}
    )
        return new(
            core,
            bvh,
            0.5
        )
    end
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
function f(meta_balls::MetaBallsBVH, ss::Set{SimpleSphere}, t::Float64, ray::AbstractRay)::Float64
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
function f(meta_balls::MetaBallsBVH, ss::Set{SimpleSphere}, pp::Pnt3)::Float64
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

# function normal(sphere_set::Set{SimpleSphere}, pp::Pnt3)::Vec3
#     n = Nml3(0, 0, 0)
#     for s in sphere_set
#         p = norm(pp-s.p)
#         if p <= s.r
#             x =  0.4444 * 6.0 * (pp.x - s.p.x) * p^4 / s.r ^ 6
#             x+= -1.8888 * 4.0 * (pp.x - s.p.x) * p^2 / s.r ^ 4
#             x+=  2.4444 * 2.0 * (pp.x - s.p.x)       / s.r ^ 2

#             y =  0.4444 * 6.0 * (pp.y - s.p.y) * p^4 / s.r ^ 6
#             y+= -1.8888 * 4.0 * (pp.y - s.p.y) * p^2 / s.r ^ 4
#             y+=  2.4444 * 2.0 * (pp.y - s.p.y)       / s.r ^ 2

#             z =  0.4444 * 6.0 * (pp.z - s.p.z) * p^4 / s.r ^ 6
#             z+= -1.8888 * 4.0 * (pp.z - s.p.z) * p^2 / s.r ^ 4
#             z+=  2.4444 * 2.0 * (pp.z - s.p.z)       / s.r ^ 2

#             n += Nml3(x,y,z)
#         end
#     end
#     return normalize(n)
# end


###############
#### PBRT #####
###############
function ObjectBounds(s::MetaBallsBVH)::Bounds3
    return s.core.world_to_object(world_bounds(s.bvh))
end

function intersect(s::MetaBallsBVH, rr::AbstractRay)::Tuple{Bool, Float64, SurfaceInteraction}
    # transform ray, note re-allocation from rr to r
    r = s.core.world_to_object(rr)

    rr_origin = rr.origin
    rr_direction = rr.direction

    check, t, intersect = intersect!(s.bvh, rr)
    (!check) && (return false, 0.0, empty_surface_interation())        
    sphere_set = Set(SimpleSphere[])
    t_set = Set(Float64[])
    ugh = 0
    while true & (ugh < 30)
        hit_shape = get_shape(intersect.shape)
        push!(sphere_set, SimpleSphere(hit_shape.core.object_to_world(Pnt3(0,0,0)), hit_shape.radius))
        idx = argmax(abs.(rr_direction))
        push!(t_set, (intersect.core.p[idx] - rr_origin[idx]) / rr_direction[idx])

        rr = with_origin_t_tmax(rr, intersect.core.p + rr_direction * .00001, 0.0, typemax(Float64))

        check, t, intersect = intersect!(s.bvh, rr)
        (!check) && break
        ugh += 1
    end
    rr = with_origin(rr, rr_origin)

    @info "MetaBallsBVHIntersectionTest: ray: $(r), active_spheres: $(sphere_set), bounds: 0.0 - $(maximum(t_set) * 1.1)"

    tmp_solve = (x -> f(s, sphere_set, x, r))

    # solve
    # HOW TO SET BOUNDS
    solutions = find_zeros(tmp_solve, minimum(t_set)/1.1, maximum(t_set)*1.1) # HACKY

    @info "MetaBallsBVHIntersectionTest: solutions: $(solutions)"

    if length(solutions) == 0
        return false, 0.0, empty_surface_interation()
    end
    
    # find intersection time
    t = minimum(solutions)

    if t > r.tMax[]
        return false, 0.0, empty_surface_interation()
    end

    # get intersection point
    p = at(r, t)

    # get surface normal
    n = normal(s, sphere_set, p)

    @info "MetaBallsBVHIntersection: p: $(p), n: $(n)"

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

function intersect_p(s::MetaBallsBVH, rr::AbstractRay)::Bool
    # transform ray, note re-allocation from rr to r
    r = s.core.world_to_object(rr)

    rr_origin = rr.origin
    rr_direction = rr.direction

    check, t, intersect = intersect!(s.bvh, rr)
    (!check) && (return false, 0.0, empty_surface_interation())        
    sphere_set = Set(SimpleSphere[])
    t_set = Set(Float64[])
    ugh = 0
    while true & (ugh < 30)
        hit_shape = get_shape(intersect.shape)
        push!(sphere_set, SimpleSphere(hit_shape.core.object_to_world(Pnt3(0,0,0)), hit_shape.radius))
        idx = argmax(abs.(rr_direction))
        push!(t_set, (intersect.core.p[idx] - rr_origin[idx]) / rr_direction[idx])

        rr = with_origin_t_tmax(rr, intersect.core.p + rr_direction * .00001, 0.0, typemax(Float64))

        check, t, intersect = intersect!(s.bvh, rr)
        (!check) && break
        ugh += 1
    end
    rr = with_origin(rr, rr_origin)

    @info "MetaBallsBVHIntersectionTest: ray: $(r), active_spheres: $(sphere_set), bounds: 0.0 - $(maximum(t_set) * 1.1)"

    tmp_solve = (x -> f(s, sphere_set, x, r))

    # solve
    # HOW TO SET BOUNDS
    solutions = find_zeros(tmp_solve, minimum(t_set)/1.1, maximum(t_set)*1.1) # HACKY

    @info "MetaBallsBVHIntersectionTest: solutions: $(solutions)"

    if length(solutions) == 0
        return false
    end
    
    # find intersection time
    t = minimum(solutions)

    if t > r.tMax[]
        return false
    end

    return true
end

#########################################
## NOT NEEDED AS LONG AS NOT EMMISSIVE ##
#########################################

function sample(s::MetaBallsBVH, u::Pnt2)::Tuple{Pnt3, Nml3}
    @assert false
end

function sample(s::MetaBallsBVH, interaction::Interaction, u::Pnt2)::Tuple{Pnt3, Nml3}
    @assert false
end
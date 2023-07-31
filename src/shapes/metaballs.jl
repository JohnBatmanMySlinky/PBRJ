struct MetaBalls <: Shape
    core::ShapeCore
    ks::Vector{Pnt3} # world space
    R::Float64
    magic::Float64
    bounding_sphere::Sphere
    
    function MetaBalls(
        core::ShapeCore, 
        ks::Vector{Pnt3}=Pnt3[Pnt3(0.0)],
        R::Float64=3.0,
        magic::Float64=0.5
    )
        # TODO 
        # clean and make a simple sphere class
        centroid = mean(ks)
        radius = maximum(maximum(Pnt3[abs.(centroid-k) for k in ks]))+R
        bounding_shere_t = Translate(centroid)
        bounding_sphere_core = ShapeCore(bounding_shere_t, Inv(bounding_shere_t), false, false)
        bounding_sphere = Sphere(bounding_sphere_core, radius)
        return new(core, ks, R, magic, bounding_sphere)
    end
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
function f(meta_balls::MetaBalls, t::Float64, ray::AbstractRay)::Float64
    f_val = 0.0 - meta_balls.magic # start at negative target so we can "solve for zero"
    for k in meta_balls.ks
        p = norm(at(ray, t)-k)
        if p <= meta_balls.R
            f_val += f_inner(p, meta_balls.R)
        end
    end
    return f_val
end

# for use in normal calc
# given a point eval f
function f(meta_balls::MetaBalls, pp::Pnt3)::Float64
    f_val = 0.0 - meta_balls.magic # do I need target here?
    for k in meta_balls.ks
        p = norm(pp-k)
        if p <= meta_balls.R
            f_val += f_inner(p, meta_balls.R)
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
function normal(meta_balls::MetaBalls, p::Pnt3)::Vec3
    e = .00001
    return normalize(
        Vec3(1, -1, -1) * f(meta_balls, p + Vec3(e, -e, -e)) +
        Vec3(-1, -1, 1) * f(meta_balls, p + Vec3(-e, -e, e)) +
        Vec3(-1, 1, -1) * f(meta_balls, p + Vec3(-e, e, -e)) +
        Vec3(1, 1, 1)   * f(meta_balls, p + Vec3(e, e, e))
    )
end

###############
#### PBRT #####
###############
function ObjectBounds(s::MetaBalls)::Bounds3
    # JOHN HACK: why is this is so ugly
    return Bounds3(
        Pnt3(
            minimum(getfield.(s.ks, 1))-s.R,
            minimum(getfield.(s.ks, 2))-s.R,
            minimum(getfield.(s.ks, 3))-s.R,
        ),
        Pnt3(
            maximum(getfield.(s.ks, 1))+s.R,
            maximum(getfield.(s.ks, 2))+s.R,
            maximum(getfield.(s.ks, 3))+s.R,
        ),
    )
end

# Due to the fact we are solving for t first, then proceeding, we can basically re-ruse all of intersect_p
# intersect_p just needs to return a bool instead of a float...
function intersect_t(s::MetaBalls, r::AbstractRay)::Float64
    # set up anonymous function for solver
    tmp_solve = (x -> f(s, x, r))

    # intersect bounding sphere
    check, t0, t1 = intersect_simple(s.bounding_sphere, r)

    # transform ray, note timing of this after the bounding sphere test
    r = s.core.world_to_object(r)

    # doesn't intersect sphere, NEXT
    if !check
        return -1.0
    end

    # TODO some checks t0 & t1 aren't negative?

    # solve
    # HOW TO SET BOUNDS
    solutions = find_zeros(tmp_solve, 0.0, t1*1.1) # HACKY

    @info "MetaBallsIntersectionTest: ray: $(r), solutions: $(solutions), bounding_sphere bounds: ($(t0/1.1), $(t1*1.1))"

    if length(solutions) == 0
        return -1.0
    end
    
    # find intersection time
    t = minimum(solutions)

    if t > r.tMax
        return -1.0
    end

    return t
end

function intersect(s::MetaBalls, r::AbstractRay)::Tuple{Bool, Float64, SurfaceInteraction}
    t = intersect_t(s, r)

    if t == -1.0
        return false, 0.0, empty_surface_interation()
    end   

    # get intersection point
    p = at(r, t)

    # get surface normal
    n = normal(s, p)

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

function intersect_p(s::MetaBalls, r::AbstractRay)::Bool
    return intersect_t(s, r) == -1.0 ? false : true
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
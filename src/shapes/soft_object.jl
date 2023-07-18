struct SoftObject <: Shape
    core::ShapeCore
    ks::Vector{Pnt3} # world space
    R::Float64
    magic::Float64
    world_diameter::Float64
    
    function SoftObject(
        core::ShapeCore, 
        ks::Vector{Pnt3}=[Pnt3(0.0)],
        R::Float64=3.0,
        magic::Float64=0.5,
        world_diameter::Float64=300.0
    )
        return new(core, ks, R, magic, world_diameter)
    end
end

#### UTILS
# for use in intersection point calc
# given ray & t
function f(soft_object::SoftObject, t::Float64, ray::AbstractRay)::Float64
    f_val = 0.0 - soft_object.magic # start at negative target so we can "solve for zero"
    for k in soft_object.ks
        p = norm(at(ray, t)-k)
        if p <= soft_object.R
            f_val += -.4444 * (p ^ 6) / (soft_object.R ^ 6) + 1.8888 * (p ^ 4) / (soft_object.R ^ 4) - 2.4444 * (p ^ 2) / (soft_object.R ^ 2) + 1.0
        end
    end
    return f_val
end

# for use in normal calc
function f(soft_object::SoftObject, pp::Pnt3)::Float64
    f_val = 0.0 - soft_object.magic # do I need target here?
    for k in soft_object.ks
        p = norm(pp-k)
        if p <= soft_object.R
            f_val += -.4444 * (p ^ 6) / (soft_object.R ^ 6) + 1.8888 * (p ^ 4) / (soft_object.R ^ 4) - 2.4444 * (p ^ 2) / (soft_object.R ^ 2) + 1.0
        end
    end
    return f_val
end

function normal(soft_object::SoftObject, p::Pnt3)::Vec3
    e = .00001
    return normalize(
        Vec3(1, -1, -1) * f(soft_object, p + Vec3(e, -e, -e)) +
        Vec3(-1, -1, 1) * f(soft_object, p + Vec3(-e, -e, e)) +
        Vec3(-1, 1, -1) * f(soft_object, p + Vec3(-e, e, -e)) +
        Vec3(1, 1, 1)   * f(soft_object, p + Vec3(e, e, e))
    )
end

############ Now back to the PBRT stuff

function ObjectBounds(s::SoftObject)::Bounds3
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

function intersect(s::SoftObject, r::AbstractRay)::Tuple{Bool, Float64, SurfaceInteraction}
    r = s.core.world_to_object(r)

    # set up anonymous function for solver
    tmp_solve = (x -> f(s, x, r))

    # solve
    # HANDLE NO SOLUTIONS
    # HOW TO SET BOUNDS
    approx_upper_bound = abs(s.world_diameter / mean(r.direction))
    solutions = find_zeros(tmp_solve, 0.0, approx_upper_bound)

    @info "SoftObjectIntersection: ray: $(r), solutions: $(solutions), approx_upper_bound: $(approx_upper_bound)"

    if length(solutions) == 0
        return false, 0.0, empty_surface_interation()
    end
    
    # find intersection time
    t = minimum(solutions)

    # get intersection point
    p = at(r, t)

    # get surface normal
    # JOHN HACK WHY THE NEGATIVE
    n = -normal(s, p)

    @info "SoftObjectIntersection: p: $(p), n: $(n)"

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
        Nml3(0.0), # KLUDGE
        Nml3(0.0), # KLUDGE
        s
    )
    return true, t, s.core.object_to_world(interaction)
end

function intersect_p(s::SoftObject, r::AbstractRay)::Bool
    r = s.core.world_to_object(r)

    # set up anonymous function for solver
    tmp_solve = (x -> f(s, x, r))

    # solve
    # HOW TO SET BOUNDS
    approx_upper_bound = abs(s.world_diameter / mean(r.direction))
    solutions = find_zeros(tmp_solve, 0.0, approx_upper_bound)

    @info "SoftObjectIntersectionTest: ray: $(r), solutions: $(solutions), approx_upper_bound: $(approx_upper_bound)"

    if length(solutions) == 0
        return false
    end

    # ray tmax check
    
    return true
end

#########################################
## NOT NEEDED AS LONG AS NOT EMMISSIVE ##
#########################################

function sample(s::SoftObject, u::Pnt2)::Tuple{Pnt3, Nml3}
    @assert false
end

function sample(s::SoftObject, interaction::Interaction, u::Pnt2)::Tuple{Pnt3, Nml3}
    @assert false
end
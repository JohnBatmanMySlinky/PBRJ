struct SoftBody <: Shape
    core::ShapeCore
    ks::Vector{Pnt3} # world space
    R::Float64
    magic::Float64
    
    function SoftBody(
        core::ShapeCore, 
        ks::Vector{Pnt3}=[Pnt3(0.0)],
        R::Float64=3.0,
        magic::Float64=0.5
    )
        return new(core, ks, R, magic)
    end
end

#### UTILS
# for use in intersection point calc
# given ray & t
function f(soft_body::SoftBody, t::Float64, ray::RayTracing.Ray)::Float64
    f_val = 0.0 - soft_body.magic # start at negative target so we can "solve for zero"
    for k in soft_body.ks
        p = RayTracing.norm(RayTracing.at(ray, t)-k)
        if p <= R
            f_val += -.4444 * (p ^ 6) / (R ^ 6) + 1.8888 * (p ^ 4) / (R ^ 4) - 2.4444 * (p ^ 2) / (R ^ 2) + 1.0
        end
    end
    return f_val
end

# for use in normal calc
function f(soft_body::SoftBody, pp::RayTracing.Pnt3)::Float64
    f_val = 0.0 - soft_body.magic # do I need target here?
    for k in soft_body.ks
        p = RayTracing.norm(pp-k)
        if p <= R
            f_val += -.4444 * (p ^ 6) / (R ^ 6) + 1.8888 * (p ^ 4) / (R ^ 4) - 2.4444 * (p ^ 2) / (R ^ 2) + 1.0
        end
    end
    return f_val
end

function normal(soft_body::SoftBody, p::Pnt3)::Vec3
    e = .00001
    return normalize(
        Vec3(1, -1, -1) * f(soft_body, p + RayTracing.Vec3(e, -e, -e)) +
        Vec3(-1, -1, 1) * f(soft_body, p + RayTracing.Vec3(-e, -e, e)) +
        Vec3(-1, 1, -1) * f(soft_body, p + RayTracing.Vec3(-e, e, -e)) +
        Vec3(1, 1, 1)   * f(soft_body, p + RayTracing.Vec3(e, e, e))
    )
end

############ Now back to the PBRT stuff

function ObjectBounds(s::SoftBody)::Bounds3
    # JOHN HACK: why is this is so ugly
    return s.core.world_to_object(# WORLD SPACE

        Bounds3(
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
    )
end

function intersect(s::SoftBody, r::AbstractRay)::Tuple{Bool, Float64, SurfaceInteraction}
    # set up anonymous function for solver
    tmp_solve = (x -> f(s, x, ray))

    # solve
    # HANDLE NO SOLUTIONS
    # HOW TO SET BOUNDS
    zeros = find_zeros(tmp_solve, 0.0, 100.0)

    # WHAT HAPPENS IF T NEGATIVE
    t = minimum(zeros)

    # get intersection point
    p = at(ray, t)

    # get surface normal
    n = normal(s, p)

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
    return true, t, interaction
end

function intersect_p(s::SoftBody, r::AbstractRay)::Bool
    #TODO
end

#########################################
## NOT NEEDED AS LONG AS NOT EMMISSIVE ##
#########################################

function sample(s::SoftBody, u::Pnt2)::Tuple{Pnt3, Nml3}
    @assert false
end

function sample(s::SoftBody, interaction::Interaction, u::Pnt2)::Tuple{Pnt3, Nml3}
    @assert false
end
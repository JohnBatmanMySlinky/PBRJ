struct MetaBalls <: ImplicitSurface
    core::ShapeCore
    ks::Vector{Pnt3} # world space
    R::Float64
    magic::Float64
    bounding_sphere::Sphere

    function MetaBalls(
        core::ShapeCore=ShapeCore(), 
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

# function normal(meta_balls::MetaBalls, pp::Pnt3)::Vec3
#     n = RayTracing.Nml3(0, 0, 0)
#     for s in meta_balls.ks
#         p = RayTracing.norm(pp-s)
#         if p <= meta_balls.R
#             # exponent goes like (E / 2 - 1 )*2
#                 # E is exp, div 2 for sqrt, minus 1 for deriv * 2 for back to sqrt terms
#                 # first factor is eq to E because the derivative of the inside gives *2 and the sqrt is a /2
#                 # note the sign change.... I think that's right.

                # MY MATH IS RIGHT
                # THIS CODE WORKS WHEN ONE BALL IS IN RANGE, NOT MORE
                # WHEN YOU HAVE ONE BALL RIGHT ON THE EDGE OF RANGE
                # THE ESTIMATED NORMAL LOOKS VERY MUCH LIKE THE NON-EDGE-OF-RANGE BALL'S NORMALIZED(N(X,Y,Z))
                # SO SOMETHING FUCKY IS HAPPENING ON THE EDGE....
#             x =   0.4444 * 6.0 * (pp.x - s.x) * p^4 / meta_balls.R ^ 6
#                  -1.8888 * 4.0 * (pp.x - s.x) * p^2 / meta_balls.R ^ 4
#                 + 2.4444 * 2.0 * (pp.x - s.x)       / meta_balls.R ^ 2

#             y =   0.4444 * 6.0 * (pp.y - s.y) * p^4 / meta_balls.R ^ 6
#                  -1.8888 * 4.0 * (pp.y - s.y) * p^2 / meta_balls.R ^ 4
#                 + 2.4444 * 2.0 * (pp.y - s.y)       / meta_balls.R ^ 2

#             z =   0.4444 * 6.0 * (pp.z - s.z) * p^4 / meta_balls.R ^ 6
#                  -1.8888 * 4.0 * (pp.z - s.z) * p^2 / meta_balls.R ^ 4
#                 + 2.4444 * 2.0 * (pp.z - s.z)       / meta_balls.R ^ 2

#             n += Nml3(x,y,z)
#         end
#     end
#     return normalize(n)
# end

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

#########################################
## NOT NEEDED AS LONG AS NOT EMMISSIVE ##
#########################################

function sample(s::MetaBalls, u::Pnt2)::Tuple{Pnt3, Nml3}
    @assert false
end

function sample(s::MetaBalls, interaction::Interaction, u::Pnt2)::Tuple{Pnt3, Nml3}
    @assert false
end
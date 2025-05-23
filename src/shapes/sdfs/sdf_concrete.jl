#############
### UTILS ###
#############

function union_bounding_spheres(sphere1::RayTracing.Sphere, sphere2::RayTracing.Sphere)::RayTracing.Sphere
    center1 = sphere1.core.world_to_object(RayTracing.Pnt3(0,0,0))
    center2 = sphere2.core.world_to_object(RayTracing.Pnt3(0,0,0))

    # Get the vector between the centers
    center_vector = center2 - center1
    center_distance = RayTracing.norm(center_vector)
    
    # If one sphere contains the other, return the larger one
    if center_distance + sphere2.radius <= sphere1.radius
        # sphere1 completely contains sphere2
        return sphere1
    elseif center_distance + sphere1.radius <= sphere2.radius
        # sphere2 completely contains sphere1
        return sphere2
    end
    
    # Otherwise, create a new sphere that encloses both
    # The new center is along the line between the centers
    # weighted by the radii
    new_center = center1 + center_vector * 0.5
    
    # The new radius must reach the furthest point of either sphere
    new_radius = (center_distance + sphere1.radius + sphere2.radius) * 0.5
    
    return RayTracing.Sphere(new_center, new_radius)
end

##################
### OPERATIONS ###
##################

# Define specific operation types
struct SDFUnion <: SDFOperation
    k::Float64  # Smoothing parameter
    left::ImplicitSurface
    right::ImplicitSurface
    bounding_sphere::RayTracing.Sphere
    core::ShapeCore

    function SDFUnion(k::Float64, left::ImplicitSurface, right::ImplicitSurface, core::ShapeCore)
        return new(k, left, right, union_bounding_spheres(left.bounding_sphere, right.bounding_sphere), core)
    end
end

#####################
### OBJECT BOUNDS ###
#####################
function ObjectBounds(s::SDFUnion)::Bounds3
    r = s.bounding_sphere.radius
    return Bounds3(
        Pnt3(-r, -r, -r),
        Pnt3(r, r, r),
    )
end

function ObjectBounds(s::SDFPrimitive)::Bounds3
    r = s.bounding_sphere.radius
    return Bounds3(
        Pnt3(-r, -r, -r),
        Pnt3(r, r, r),
    )
end

##################
### PRIMITIVES ###
##################
# https://iquilezles.org/articles/distfunctions/

struct SDFSphere <: SDFPrimitive
    radius::Float64
    core::RayTracing.ShapeCore
    bounding_sphere::RayTracing.Sphere
end

struct SDFBox <: SDFPrimitive
    half_extents::RayTracing.Pnt3  # half-width, half-height, half-depth
    core::RayTracing.ShapeCore
    bounding_sphere::RayTracing.Sphere
end

struct SDFTorus <: SDFPrimitive
    t::Vec2
    core::RayTracing.ShapeCore
    bounding_sphere::RayTracing.Sphere
end

struct SDFFrameBox <: SDFPrimitive
    b::Pnt3
    e::Float64
    core::ShapeCore
    bounding_sphere::Sphere
end

struct SDFRoundedCone <: SDFPrimitive
    r1::Float64
    r2::Float64
    h::Float64
    core::ShapeCore
    bounding_sphere::Sphere
end

struct SDFHexagonalPrism <: SDFPrimitive
    h::Vec2
    core::ShapeCore
    bounding_sphere::Sphere
end

struct SDFQuad <: SDFPrimitive
    a::Vec3
    b::Vec3
    c::Vec3
    d::Vec3
    core::ShapeCore
    bounding_sphere::Sphere

    function SDFQuad(a::Vec3, b::Vec3, c::Vec3, d::Vec3, core::ShapeCore, bounding_sphere::Sphere)::SDFQuad
        ba = b - a
        ad = a - d
        nor = cross(ba, ad)
        plane_tolerance = 1e-10
        nor_normalized = nor / norm(nor)
    
        # let's make sure your vertices aren't ordered incorrectly
        @assert abs(dot(nor_normalized, b - a)) < plane_tolerance "Vertices are not coplanar - check vertex ordering"
        @assert abs(dot(nor_normalized, c - a)) < plane_tolerance "Vertices are not coplanar - check vertex ordering"  
        @assert abs(dot(nor_normalized, d - a)) < plane_tolerance "Vertices are not coplanar - check vertex ordering"
        @assert norm(nor) > plane_tolerance "Degenerate quadrilateral - vertices are collinear or coincident"
        return new(a, b, c, d, core, bounding_sphere)
    end
end

###################
### EVALUTATION ###
###################

# Primitive evaluations
function evaluate(shape::SDFSphere, p::RayTracing.Pnt3)::Float64
    # Transform point to object space
    local_p = shape.core.world_to_object(p)
    # Sphere SDF: length(p) - radius
    return RayTracing.norm(local_p) - shape.radius
end

function evaluate(shape::SDFBox, p::RayTracing.Pnt3)::Float64
    # Transform point to object space
    local_p = shape.core.world_to_object(p)
    # Box SDF implementation
    q = abs.(local_p) .- shape.half_extents
    return RayTracing.norm(max.(q, 0.0)) + min(maximum(q), 0.0)
end

function evaluate(shape::SDFTorus, p::RayTracing.Pnt3)::Float64
    q = Vec2(sqrt(p.x^2 + p.z^2) - shape.t.x, p.y)
    return sqrt(q.x^2 + q.y^2) - shape.t.y
end

function evaluate(shape::SDFFrameBox, p::Pnt3)::Float64
    p = abs.(p) .- shape.b
    q = abs.(p .+ shape.e) .- shape.e
    
    case1 = length_pbrt(max.(Pnt3(p.x, q.y, q.z), 0.0)) + min(max(p.x, max(q.y, q.z)), 0.0)
    case2 = length_pbrt(max.(Pnt3(q.x, p.y, q.z), 0.0)) + min(max(q.x, max(p.y, q.z)), 0.0)
    case3 = length_pbrt(max.(Pnt3(q.x, q.y, p.z), 0.0)) + min(max(q.x, max(q.y, p.z)), 0.0)
    
    return min(min(case1, case2), case3)
end

function evaluate(shape::SDFRoundedCone, p::Pnt3)::Float64
    # Sampling independent computations
    b = (shape.r1 - shape.r2) / shape.h
    a = sqrt(1.0 - b * b)
    
    # Sampling dependent computations
    q = Vec2(sqrt(p.x^2 + p.z^2), p.y)
    k = dot(q, Vec2(-b, a))
    
    if k < 0.0
        return length_pbrt(q) - shape.r1
    elseif k > a * shape.h
        return length_pbrt(q - Vec2(0.0, shape.h)) - shape.r2
    else
        return dot(q, Vec2(a, b)) - shape.r1
    end
end

function evaluate(shape::SDFHexagonalPrism, p::Pnt3)::Float64
    k = Vec3(-0.8660254, 0.5, 0.57735)
    p = abs.(p)
    pxy = sqrt(p.x^2 + p.y^2)
    pxy -= 2.0 * min(dot(sqrt(k.x^2 + k.y^2), pxy), 0.0) * sqrt(k.x^2 + k.y^2)
    d = Vec2(
        length_pbrt(pxy .- Vec2(clamp(p.x , -k.z * shape.h.x, k.z * shape.h.x), shape.h.x)) * sign(p.y - shape.h.x),
        p.z - shape.h.y
    )
    return min(max(d.x, d.y), 0.0) + length_pbrt(max.(d, 0.0))
end

function evaluate(shape::SDFQuad, p::Pnt3)::Float64
    ba = shape.b - shape.a
    pa = p       - shape.a
    cb = shape.c - shape.b
    pb = p       - shape.b  
    dc = shape.d - shape.c
    pc = p       - shape.c
    ad = shape.a - shape.d
    pd = p       - shape.d
    
    nor = cross(ba, ad)

    dot2(v) = dot(v, v)
    
    inside_test = (sign(dot(cross(ba, nor), pa)) +
                   sign(dot(cross(cb, nor), pb)) + 
                   sign(dot(cross(dc, nor), pc)) +
                   sign(dot(cross(ad, nor), pd)))
    
    if inside_test < 3
        dist_ba = dot2(ba * clamp(dot(ba, pa) / dot2(ba), 0.0, 1.0) - pa)
        dist_cb = dot2(cb * clamp(dot(cb, pb) / dot2(cb), 0.0, 1.0) - pb)
        dist_dc = dot2(dc * clamp(dot(dc, pc) / dot2(dc), 0.0, 1.0) - pc)
        dist_ad = dot2(ad * clamp(dot(ad, pd) / dot2(ad), 0.0, 1.0) - pd)
        
        return sqrt(min(dist_ba, dist_cb, dist_dc, dist_ad))
    else
        return sqrt(dot(nor, pa)^2 / dot2(nor))
    end
end

# OK NOTE THIS...
function normal(shape::SDFQuad, ::Pnt3)::Nml3
    edge1 = shape.b - shape.a
    edge2 = shape.d - shape.a  # or (c - b) depending on your preference
    normal = cross(edge1, edge2)
    return normalize(normal)
end

# Operation evaluations
function evaluate(op::SDFUnion, p::RayTracing.Pnt3)::Float64
    a = evaluate(op.left, p) 
    b = evaluate(op.right, p)
    
    # Smooth union formula
    # https://iquilezles.org/articles/smin/
    if op.k > 0
        k2 = op.k * 6.0
        h = max( k2-abs(a-b), 0.0 )/k2
        return min(a,b) - h*h*h*k2*(1.0/6.0)
    else
        # Regular union
        return min(a, b)
    end
end

#################
### INTERFACE ###
#################

# Main evaluation function - dispatches to specialized methods
function f(element::ImplicitSurface, p::RayTracing.Pnt3)::Float64
    return evaluate(element, p)
end

# Compatibility with ray evaluation
function f(element::ImplicitSurface, t::Float64, r::RayTracing.AbstractRay)::Float64
    return f(element, RayTracing.at(r, t))
end
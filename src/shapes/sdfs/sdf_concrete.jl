################
### ABSTRACT ###
################

# Base abstract type for all SDF components
# abstract type ImplicitSurface end

# Primitive SDF shapes inherit from this
abstract type SDFPrimitive <: ImplicitSurface end

# Operations (union, intersection, etc.) inherit from this
abstract type SDFOperation <: ImplicitSurface end

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

##################
### PRIMITIVES ###
##################

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

# Operation evaluations
function evaluate(op::SDFUnion, p::RayTracing.Pnt3)::Float64
    a = evaluate(op.left, p) 
    b = evaluate(op.right, p)
    
    # Smooth union formula
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
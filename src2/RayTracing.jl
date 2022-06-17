module RayTracing

using StaticArrays
using LinearAlgebra

abstract type Aggregate end
abstract type Shape end
abstract type Camera end
abstract type Sampler end
abstract type Filter end
abstract type Material end
abstract type Texture end
abstract type Medium end
abstract type Light end
abstract type Integrator end

include("vec.jl")
include("ray.jl")
include("interactions.jl")
include("transformations.jl")
include("shapes/shape.jl")
include("shapes/sphere.jl")
include("math.jl")

dummy_transform = Translate(Vec3(0, 0, 0))

dummy_sphere = Sphere(
    ShapeCore(
        dummy_transform,      # object_to_world
        Inv(dummy_transform)  # world_to_object
    ),
    5.0,                      # radius
    0.0,                      # zMin
    5.0,                      # zMax
    0.0,                      # thetaMin
    2pi,                      # thetaMax
    2pi                       # phiMax
)

dummy_ray = Ray(Vec3(10, 10, 10), Vec3(-1, -1, -1), 0, typemax(Float64))

check, t, interaction = Intersect(dummy_sphere, dummy_ray)

print(interaction.core.p)


print("\nhahaha\n")

end
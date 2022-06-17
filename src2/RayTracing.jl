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

dummy_transform = Transformation(
    Mat4([1 1 1 1; 1 1 1 1; 1 1 1 1; 1 1 1 1]),
    Mat4([1 1 1 1; 1 1 1 1; 1 1 1 1; 1 1 1 1]),
)

dummy_sphere = Sphere(
    ShapeCore(
        dummy_transform,
        dummy_transform
    ),
    5,
    0,
    5,
    0,
    2pi,
    2pi
)

dummy_ray = Ray(Vec3(10, 10, 10), Vec3(0,0,0), 0, typemax(Float64))

check, t, interaction = Intersect(dummy_sphere, dummy_ray)

print(interaction.core.p)


print("\nhahaha\n")

end
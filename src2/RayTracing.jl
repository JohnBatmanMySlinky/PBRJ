module RayTracing

using StaticArrays

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



print("hahaha")

end
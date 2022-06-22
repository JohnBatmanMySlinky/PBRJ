using StaticArrays
using LinearAlgebra

abstract type Aggregate end
abstract type BxDF end
abstract type Camera end
abstract type Filter end
abstract type Integrator end
abstract type Light end
abstract type Material end
abstract type Medium end
abstract type AbstractSampler end
abstract type Shape end
abstract type Texture end

include("vec.jl")
include("ray.jl")
include("primitive.jl")
include("interactions.jl")
include("transformations.jl")

point = Vec3(1, 2, 3)

dummy_transform2 = Translate(Vec3(-3, -3, -3))
asdf = Inv(dummy_transform2)

print(dummy_transform2(point))
print(asdf(point2))
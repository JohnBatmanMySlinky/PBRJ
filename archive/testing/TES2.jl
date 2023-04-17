using StaticArrays
using LinearAlgebra
using FileIO

abstract type Aggregate end
abstract type AbstractBxDF end
abstract type AbstractBSDF end
abstract type Camera end
abstract type Filter end
abstract type Fresnel end
abstract type AbstractIntegrator end
abstract type Light end
abstract type Material end
abstract type Medium end
abstract type AbstractSampler end
abstract type Shape end
abstract type Texture end

const Radiance = Val{:Radiance}
const Importance = Val{:Importance}
const TransportMode = Union{Radiance, Importance}

include("objects.jl")
include("primitive.jl")
include("interactions.jl")
include("transformations.jl")
include("shapes/shape.jl")
include("shapes/sphere.jl")
include("shapes/triangle.jl")
include("math_utils.jl")
include("accelerators/bvh.jl")
include("filters/box.jl")
include("film.jl")
include("cameras/camera.jl")
include("cameras/projective.jl")
include("samplers/sampler.jl")
include("samplers/random.jl")
include("reflection/bxdf.jl")
include("reflection/math.jl")
include("reflection/fresnel.jl")
include("reflection/specular.jl")
include("reflection/lambertian.jl")
include("materials/bsdf.jl")
include("materials/matte.jl")
include("materials/mirror.jl")
include("textures/constant.jl")
include("lights/light.jl")
include("lights/point.jl")
include("scene.jl")
include("integrators/whitted.jl")
include("handy_prints.jl")

function yeehaw()
    dummy_transform3 = Translate(Pnt3(0, 0, 0))
    triangles = construct_triangle_mesh(
        ShapeCore(dummy_transform3, Inv(dummy_transform3)),                 # ShapeCore
        2,                                                                  # n_triangles                              
        4,                                                                  # n_verices\
        [
            Pnt3(0, 0, 0), Pnt3(0, 0, -30),
            Pnt3(30, 0, -30), Pnt3(30, 0, 0),
        ], # vertices
        Int64[1, 2, 3, 1, 4, 3],                                                 # indices          
        [Nml3(0, 1, 0), Nml3(0, 1, 0), Nml3(0, 1, 0), Nml3(0, 1, 0)],       # normals
    )

    r = Ray(Pnt3(300, 300, 300), normalize(Vec3(-1, -1, -1)), 0, typemax(Float64))

    check, t, inter = Intersection(triangles[1], r)

    print("hit? $(check)\n")
    print("time? $(t)")
end

@time yeehaw()


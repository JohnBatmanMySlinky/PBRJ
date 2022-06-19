module RayTracing

using StaticArrays
using LinearAlgebra

abstract type Aggregate end
abstract type Camera end
abstract type Filter end
abstract type Integrator end
abstract type Light end
abstract type Material end
abstract type Medium end
abstract type Sampler end
abstract type Shape end
abstract type Texture end

include("vec.jl")
include("ray.jl")
include("primitive.jl")
include("interactions.jl")
include("transformations.jl")
include("shapes/shape.jl")
include("shapes/sphere.jl")
include("math.jl")
include("materials/materials.jl")
include("accelerators/bvh.jl")

function something(N::Int64)
    # create shapes
    dummy_transform1 = Translate(Vec3(0, 0, 0))
    dummy_sphere1 = Sphere(
        ShapeCore(
            dummy_transform1,      # object_to_world
            Inv(dummy_transform1)  # world_to_object
        ),
        5.0,                       # radius
        0.0,                       # zMin
        5.0,                       # zMax
        0.0,                       # thetaMin
        2pi,                       # thetaMax
        2pi                        # phiMax
    )

    # create dummy material
    dummy_mat = DummyMaterial(Vec3(1,1,1))

    # create geometric primitives
    p1 = Primitive(dummy_sphere1, dummy_mat)

    # vector of primtives
    primitives = [p1]

    # add MANY dummy spheres
    for i = 1:N
        dummy_transform2 = Translate(Vec3(rand(1:sqrt(N)), rand(1:sqrt(N)), rand(1:sqrt(N))))
        dummy_sphere2 = Sphere(
            ShapeCore(
                dummy_transform2,      # object_to_world
                Inv(dummy_transform2)  # world_to_object
            ),
            5.0,                       # radius
            0.0,                       # zMin
            5.0,                       # zMax
            0.0,                       # thetaMin
            2pi,                       # thetaMax
            2pi                        # phiMax
        )
        tmp_p = Primitive(dummy_sphere2, dummy_mat)
        push!(primitives, tmp_p)
    end

    # instantiate accelerator
    BVH = ConstructBVH(primitives)

    # instantiate dummy ray
    dummy_ray = Ray(Vec3(10, 10, 10), Vec3(-1, -1, -1), 0, typemax(Float64))

    # intersect
    check, t, interaction = Intersect(BVH, dummy_ray)

    # print intersection
    print(interaction.core.p)
    print("\nhahaha\n")
end



@time something(10)

end
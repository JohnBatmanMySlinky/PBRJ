module RayTracing

using StaticArrays
using LinearAlgebra

abstract type Aggregate end
abstract type AbstractBxDF end
abstract type Camera end
abstract type Filter end
abstract type Fresnel end
abstract type Integrator end
abstract type Light end
abstract type Material end
abstract type Medium end
abstract type AbstractSampler end
abstract type Shape end
abstract type Texture end

include("objects.jl")
include("primitive.jl")
include("interactions.jl")
include("transformations.jl")
include("shapes/shape.jl")
include("shapes/sphere.jl")
include("math_utils.jl")
include("materials/material.jl")
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



function something(N::Int64)
    # create shapes
    dummy_transform1 = Translate(Vec3(0, 0, 0))
    dummy_sphere1 = Sphere(
        ShapeCore(
            dummy_transform1,      # object_to_world
            Inv(dummy_transform1)  # world_to_object
        ),
        5.0,                       # radius
        -5.0,                      # zMin
        5.0,                       # zMax
        0.0,                       # thetaMin
        2pi,                       # thetaMax
        2pi                        # phiMax
    )

    dummy_transform2 = Translate(Vec3(-3, -3, -3))
    dummy_sphere2 = Sphere(
        ShapeCore(
            dummy_transform2,      # object_to_world
            Inv(dummy_transform2)  # world_to_object
        ),
        5.0,                       # radius
        -5.0,                      # zMin
        5.0,                       # zMax
        0.0,                       # thetaMin
        2pi,                       # thetaMax
        2pi                        # phiMax
    )

    # create dummy material
    dummy_mat = DummyMaterial(Pnt3(1,1,1))

    # create geometric primitives
    p1 = Primitive(dummy_sphere1, dummy_mat)
    p2 = Primitive(dummy_sphere2, dummy_mat)

    # vector of primtives
    primitives = [p1, p2]

    # instantiate accelerator
    BVH = ConstructBVH(primitives)

    # instantiate a filter
    filter = BoxFilter(Pnt2(1.0, 1.0))

    # Construct a Film for Camera
    film = Film(
        Pnt2(256, 256),
        Bounds2(Pnt2(0,0), Pnt2(1,1)),
        filter,
        1.0,
        1.0,
        "yeehaw.png"
    )

    # Construct a Camera
    look_from = Pnt3(30, 30, 30)
    look_at = Pnt3(0, 0, 0)
    up = Pnt3(0, 1, 0)
    screen = Bounds2(Pnt2(-1, -1), Pnt2(1, 1))
    camera = PerspectiveCamera(LookAt(look_from, look_at, up), screen, 0.0, 1.0, 0.0, 1e6, 90.0, film)

    # construct a sampler to generate CameraSample
    uniform_sampler = UniformSampler(1)

    # generate camera samples
    camera_sample = get_camera_sample(uniform_sampler, film.full_resolution ./ 2)

    # generate ray from Camera
    dummy_ray, _ = generate_ray(camera, camera_sample)

    # intersect
    check, t, interaction = Intersect(BVH, dummy_ray)
    
    # print intersection
    print(interaction.core.p)
    print("\nhahaha\n")
end



@time something(10)

end
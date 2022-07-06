module RayTracing

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

function test_integrate()
    # create shapes
    ball_1_transform = Translate(Pnt3(6, 5, 6))
    ball_1 = Sphere(
        ShapeCore(
            ball_1_transform,      # object_to_world
            Inv(ball_1_transform)  # world_to_object
        ),
        5.0,                       # radius
    )

    ball_2_transform = Translate(Pnt3(-6, 5, -6))
    ball_2 = Sphere(
        ShapeCore(
            ball_2_transform,      # object_to_world
            Inv(ball_2_transform)  # world_to_object
        ),
        5.0,                       # radius
    )

    ball_3_transform = Translate(Pnt3(-6, 5, 6))
    ball_3 = Sphere(
        ShapeCore(
            ball_3_transform,      # object_to_world
            Inv(ball_3_transform)  # world_to_object
        ),
        5.0,                       # radius
    )

    ball_4_transform = Translate(Pnt3(6, 5, -6))
    ball_4 = Sphere(
        ShapeCore(
            ball_4_transform,      # object_to_world
            Inv(ball_4_transform)  # world_to_object
        ),
        5.0,                       # radius
    )

    floor_transform = Translate(Pnt3(0, 0, 0))
    floor_tri = construct_triangle_mesh(
        ShapeCore(floor_transform, Inv(floor_transform)),                 # ShapeCore
        2,                                                                  # n_triangles                              
        4,                                                                  # n_verices\
        [Pnt3(-150, 0, -150), Pnt3(-150, 0, 150), Pnt3(150, 0, -150), Pnt3(150, 0, 150)], # vertices
        Int64[1,3,2,3,2,4],                                                 # indices          
        [Nml3(0, 1, 0), Nml3(0, 1, 0), Nml3(0, 1, 0), Nml3(0, 1, 0)],       # normals
    )

    # create dummy material
    mat_white = Matte(ConstantTexture(Pnt3(1,1,1)), ConstantTexture(Pnt3(0, 0, 0)))
    mat_bluegreen = Matte(ConstantTexture(Pnt3(0,1,1)), ConstantTexture(Pnt3(0, 0, 0)))

    # create geometric primitives
    p1 = Primitive(ball_1, mat_bluegreen)
    p2 = Primitive(ball_2, mat_bluegreen)
    p3 = Primitive(ball_3, mat_bluegreen)
    p4 = Primitive(ball_4, mat_bluegreen)

    # vector of primtives
    primitives = [p1, p2, p3, p4]

    # add in ya triangles
    for triangle in floor_tri
        push!(primitives, Primitive(triangle, mat_white))
    end

    print("\nThere are $(length(primitives)) objects in the scene\n")

    # instantiate accelerator
    BVH = ConstructBVH(primitives)

    # print_BVH_bounds(BVH)

    # Instantiate a Filter
    filter = BoxFilter(Pnt2(1, 1))

    # Instantiate a Film
    film = Film(
        Pnt2(512, 512),
        Bounds2(Pnt2(0,0), Pnt2(1,1)),
        filter,
        1.0,
        1.0,
        "yeehaw.png"
    )

    # Instantiate a Camera
    look_from = Pnt3(300, 300, 300)
    look_at = Pnt3(-20, -15, 0) # TODO something is off here....
    up = Pnt3(0, 1, 0)
    screen = Bounds2(Pnt2(-1, -1), Pnt2(1, 1))
    C = PerspectiveCamera(LookAt(look_from, look_at, up), screen, 0.0, 1.0, 0.0, 1e6, 140.0, film)

    # Instantiate a Sampler
    S = UniformSampler(1) 
    
    # instantiate point light
    light_intensity = 250
    lights = Light[]
    push!(lights, PointLight(Translate(Pnt3(0, 12, 0)), Spectrum(light_intensity, light_intensity, light_intensity)))

    # Instantiate Scene
    scene = Scene(lights, BVH)
    
    # Instantiate an Integrator
    I = WhittedIntegrator(C, S, 1)

    render(I, scene)
end


@time test_integrate()
# @time something(10)

end
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
    dummy_transform1 = Translate(Pnt3(0, 17, 0))
    dummy_sphere1 = Sphere(
        ShapeCore(
            dummy_transform1,      # object_to_world
            Inv(dummy_transform1)  # world_to_object
        ),
        5.0,                       # radius
    )

    dummy_transform2 = Translate(Pnt3(0, 5, 0))
    dummy_sphere2 = Sphere(
        ShapeCore(
            dummy_transform2,      # object_to_world
            Inv(dummy_transform2)  # world_to_object
        ),
        5.0,                       # radius
    )

    dummy_transform3 = Translate(Pnt3(0, 0, 0))
    triangles = construct_triangle_mesh(
        ShapeCore(dummy_transform3, Inv(dummy_transform3)),                 # ShapeCore
        2,                                                                  # n_triangles                              
        4,                                                                  # n_verices\
        [Pnt3(-15, 0, -15), Pnt3(-15, 0, 15), Pnt3(15, 0, -15), Pnt3(15, 0, 15)], # vertices
        Int64[1,3,2,3,2,4],                                                 # indices          
        [Nml3(0, 1, 0), Nml3(0, 1, 0), Nml3(0, 1, 0), Nml3(0, 1, 0)],       # normals
    )

    # create dummy material
    mat_white = Matte(ConstantTexture(Pnt3(1,1,1)), ConstantTexture(Pnt3(0, 0, 0)))
    mat_bluegreen = Matte(ConstantTexture(Pnt3(0,1,1)), ConstantTexture(Pnt3(0, 0, 0)))
    mat_mirror = Mirror(ConstantTexture(Pnt3(.75, .75, .75)))

    # create geometric primitives
    p1 = Primitive(dummy_sphere1, mat_bluegreen)
    p2 = Primitive(dummy_sphere2, mat_bluegreen)

    # vector of primtives
    primitives = [p1, p2]

    # add in ya triangles
    for triangle in triangles
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
    push!(lights, PointLight(Translate(Pnt3(6, 12, 8)), Spectrum(light_intensity/2, light_intensity/2, light_intensity/2)))
    push!(lights, PointLight(Translate(Pnt3(8, 12, 6)), Spectrum(light_intensity/2, light_intensity/2, light_intensity/2)))

    push!(lights, PointLight(Translate(Pnt3(15, 25, 0)), Spectrum(light_intensity, light_intensity, light_intensity)))
    push!(lights, PointLight(Translate(Pnt3(0, 25, 15)), Spectrum(light_intensity, light_intensity, light_intensity)))

    push!(lights, PointLight(Translate(Pnt3(0, 35, 3)), Spectrum(light_intensity*2, light_intensity*2, light_intensity*2)))
    push!(lights, PointLight(Translate(Pnt3(10, 40, 6)), Spectrum(light_intensity*2, light_intensity*2, light_intensity*2)))

    # Instantiate Scene
    scene = Scene(lights, BVH)
    
    # Instantiate an Integrator
    I = WhittedIntegrator(C, S, 5)

    render(I, scene)
end


@time test_integrate()
# @time something(10)

end
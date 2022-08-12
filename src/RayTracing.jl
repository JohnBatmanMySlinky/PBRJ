module RayTracing

using StaticArrays
using LinearAlgebra
using FileIO
using Images
using Statistics
using ProgressMeter
using Random

abstract type Aggregate end
abstract type AbstractBxDF end
abstract type AbstractBSDF end
abstract type AbstractRay end
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
abstract type MicrofacetDistribution end

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
include("shapes/rectangles.jl")
include("math_utils.jl")
include("rand_utils.jl")
include("accelerators/bvh.jl")
include("filters/box.jl")
include("film.jl")
include("distributions.jl")
include("cameras/camera.jl")
include("cameras/projective.jl")
include("samplers/sampler.jl")
include("samplers/random.jl")
include("samplers/stratified.jl")
include("reflection/bxdf.jl")
include("reflection/math.jl")
include("reflection/fresnel.jl")
include("reflection/specular.jl")
include("reflection/lambertian.jl")
include("reflection/oren_nayar.jl")
include("reflection/microfacet_distributions.jl")
include("reflection/microfacet.jl")
include("materials/bsdf.jl")
include("materials/matte.jl")
include("materials/plastic.jl")
include("materials/mirror.jl")
include("textures/constant.jl")
include("textures/image.jl")
include("lights/light.jl")
include("lights/area.jl")
include("lights/point.jl")
include("lights/infinite.jl")
include("scene.jl")
include("integrators/whitted.jl")
include("handy_prints.jl")
include("obj_reader.jl")

function test_integrate()
    floor_transform = Translate(Pnt3(0, -50, 0))
    floor = XZRectangle(
        floor_transform, 
        Pnt2(-300, 300),
        Pnt2(-300, 300),
        0.0,
        false,
        false
    )

    mat_white = Matte(
        ConstantTexture(Pnt3(1,1,1)),
        ConstantTexture(Pnt3(0, 0, 0)),
        nothing
    )
    mat_bluegreen = Matte(
        ConstantTexture(Pnt3(0,1,1)),
        ConstantTexture(Pnt3(0, 0, 0)),
        nothing
    )
    mat_bluegreen_ON = Matte(
        ConstantTexture(Pnt3(0,1,1)),
        ConstantTexture(Pnt3(0, 0, 0)),
        ConstantTexture(Pnt3(.5, .5, .5)),
    )
    mat_concrete = Matte(
        ImageTexture("../ref/Stone_Floor_007_basecolor.jpg"),
        ConstantTexture(Pnt3(0,0,0)),
        nothing
        # ImageTexture("../ref/Stone_Floor_007_basecolor_edit.jpg")
    )

    mat_plastic = Plastic(
        ConstantTexture(Pnt3( 0,   1,  1)),
        ConstantTexture(Pnt3( 1,   1,  1)),
        ConstantTexture(Pnt3(.5, .5, .5)),
        nothing,
        false
    )

    mat_mirror = Mirror(
        ConstantTexture(Pnt3(.5, .5, .5))
    )

    # vector of primitives
    primitives = Primitive[]

    # add floor
    push!(primitives, Primitive(floor, mat_concrete, nothing))

    # read in Lambertian teapot
    teapot_transform = Translate(Vec3(85, 0, 0))
    teapot_tri = parse_obj("../ref/teapot.obj", teapot_transform, true, false)
    for triangle in teapot_tri
        push!(primitives, Primitive(triangle, mat_bluegreen, nothing))
    end

    # read in Oren-Nayer teapot
    teapot_transform = Translate(Vec3(-120, 0, 0))
    teapot_tri = parse_obj("../ref/teapot.obj", teapot_transform, true, false)
    for triangle in teapot_tri
        push!(primitives, Primitive(triangle, mat_bluegreen, nothing))
    end

    # read in Plastic teapot
    teapot_transform = Translate(Vec3(-120, 0, 200))
    teapot_tri = parse_obj("../ref/teapot.obj", teapot_transform, true, false)
    for triangle in teapot_tri
        push!(primitives, Primitive(triangle, mat_bluegreen, nothing))
    end

    # read in Plastic teapot
    teapot_transform = Translate(Vec3(100, 0, 200))
    teapot_tri = parse_obj("../ref/teapot.obj", teapot_transform, true, false)
    for triangle in teapot_tri
        push!(primitives, Primitive(triangle, mat_bluegreen, nothing))
    end

    # Lights
    lights = Light[]

    # instantiate an area light
    for t in [Translate(Pnt3(0, 100, -100)), Translate(Pnt3(50, 100, 100))]
        light_orb = Sphere(
            ShapeCore(t, Inv(t), false, false),
            20.0
        )
        area_light = DiffuseAreaLight(
            Spectrum(5.0, 5.0, 5.0),
            light_orb,
        )
        push!(lights, area_light)
        push!(primitives, Primitive(light_orb, mat_white, area_light))
    end

    # instantiate accelerator
    print("\nThere are $(length(primitives)) objects in the scene, building BVH\n")
    BVH = ConstructBVH(primitives)
    print("Done building BVH\n")

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
    look_from = Pnt3(800, 500, 800)
    look_at = Pnt3(300, -200, 0) # TODO something is off here....
    up = Vec3(0, -1, 0)
    screen = Bounds2(Pnt2(-1, -1), Pnt2(1, 1))
    C = PerspectiveCamera(LookAt(look_from, look_at, up), screen, 0.0, 1.0, 0.0, 1e6, 175.0, film)

    # Instantiate a Sampler
    S = StratifiedSampler(2, 2, 6, true)

    # instantiate an env light
    env_light = InfinteLight(BVH, Translate(Vec3(0,0,0)), Translate(Vec3(0,0,0)), Spectrum(.5,.5,.5), "../ref/parking_lot.jpg")
    push!(lights, env_light)

    # Instantiate Scene
    scene = Scene(lights, BVH)
    
    # Instantiate an Integrator
    I = WhittedIntegrator(C, S, 25)

    render(I, scene)
end


@time test_integrate()
# @time something(10)

end
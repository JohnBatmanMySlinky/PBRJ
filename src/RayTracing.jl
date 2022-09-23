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
abstract type BVHAccel end
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
include("accelerators/bvh_naive.jl")
include("accelerators/bvh_pbr_pxlth.jl")
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

function make_your_scene()
    floor_transform = Translate(Pnt3(0, 0, 0))
    floor = XZRectangle(
        floor_transform, 
        Pnt2(-300, 300),
        Pnt2(-300, 300),
        0.0,
        false,
        false
    )

    mat_concrete = Matte(
        ImageTexture("../ref/Stone_Floor_007_basecolor.jpg"),
        ConstantTexture(Pnt3(0,0,0)),
        ImageTexture("../ref/Stone_Floor_007_basecolor_edit.jpg")
    )

    # vector of primitives
    primitives = Primitive[]

    # add floor
    push!(primitives, Primitive(floor, mat_concrete, nothing))

    # Lights
    lights = Light[]

    # instantiate an area light
    for t in [Translate(Pnt3(0, 100, 0)), Translate(Pnt3(250, 100, 0)), Translate(Pnt3(-250, 100, 0))]
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
    print("\nThere are " * num2str(length(primitives)) * " objects in the scene, building BVH\n")
    @time bvh = BVH(primitives)
    print("Done building BVH\n")

    # instantiate an env light
    env_light = InfinteLight(bvh, Translate(Vec3(0,0,0)), Translate(Vec3(0,0,0)), Spectrum(.5,.5,.5), "../ref/parking_lot.jpg")
    push!(lights, env_light)

    # Instantiate Scene
    scene = Scene(lights, bvh)
    return scene
end

function RENDER(scene::Scene, minimal::Bool, n_samples::Int64, dim::Int64, LA_X::Int32, LA_Y::Int32, LA_Z::Int32, LF_X::Int32, LF_Y::Int32, LF_Z::Int32)
    # Instantiate a Filter
    filter = BoxFilter(Pnt2(.5, .5))

    # Instantiate a Film
    film = Film(
        Pnt2(dim, dim),
        Bounds2(Pnt2(0,0), Pnt2(1,1)),
        filter,
        1.0,
        1.0,
        "yeehaw.png"
    )

    # Instantiate a Camera
    look_from = Pnt3(LF_X, LF_Y, LF_Z)
    look_at = Pnt3(LA_X, LA_Y, LA_Z) # TODO something is off here....
    up = Vec3(0, -1, 0)
    screen = Bounds2(Pnt2(-1, -1), Pnt2(1, 1))
    C = PerspectiveCamera(LookAt(look_from, look_at, up), screen, 0.0, 1.0, 0.0, 1e6, 175.0, film)

    # Instantiate a Sampler
    S = StratifiedSampler(n_samples, n_samples, n_samples, true)
    print("Using " * num2str(S.samples_per_pixel) * " samples per pixel")
    
    # Instantiate an Integrator
    I = WhittedIntegrator(C, S, 25)

    @time render(I, scene, minimal)
    return true
end


end
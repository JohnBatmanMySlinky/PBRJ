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
include("shapes/disk.jl")
include("shapes/cylindar.jl")
include("shapes/box.jl")
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
include("textures/procedural.jl")
include("lights/light.jl")
include("lights/area.jl")
include("lights/point.jl")
include("lights/infinite.jl")
include("scene.jl")
include("integrators/whitted.jl")
include("handy_prints.jl")
include("obj_reader.jl")

function test_integrate()
    ###########################
    ######## Materials ########
    ###########################
    mat_white = Matte(
        ConstantTexture(Vec3(1, 1, 1)),
        ConstantTexture(Vec3(0, 0, 0)),
        nothing
    )
    mat_red = Matte(
        ConstantTexture(Vec3(1, 0, 0)),
        ConstantTexture(Vec3(0, 0, 0)),
        nothing
    )
    mat_green = Matte(
        ConstantTexture(Vec3(0, 1, 0)),
        ConstantTexture(Vec3(0, 0, 0)),
        nothing
    )
    mat_blue = Matte(
        ConstantTexture(Vec3(0, 0, 1)),
        ConstantTexture(Vec3(0, 0, 0)),
        nothing
    )
    mat_concrete = Matte(
        ImageTexture("../ref/Stone_Floor_007_basecolor.jpg"),
        ConstantTexture(Pnt3(0,0,0)),
        ImageTexture("../ref/Stone_Floor_007_basecolor_edit.jpg")
    )

    ###################################
    ###### GEOMETRICAL CONSTANTS ######
    ###################################

    ceiling_height = 200.0 # ~10ft * 20
    hallway_width = 160.0 # ~8ft * 20
    pillar_width_1 = 60.0 # ~4.5ft * 20
    pillar_width_2 = 20.0 # ~ 1.5ft * 20
    foyer_dim = 800.0 # ~30ft * 20
    ceiling_whole_size = 130.0 # ~6.5ft * 20
    ceiling_circle_thickness = 20.0 # ~1ft * 20
    ceiling_circle_offset = 10.0 # ~6in * 20
    pillar_alight_trim = 1.0

    ########################
    #### GEOMETRY ##########
    ########################
    floor_transform = Translate(Pnt3(0,0,0))
    floor = Rectangle(
        Pnt2(-foyer_dim/2, -foyer_dim/2), 
        Pnt2(foyer_dim/2, foyer_dim/2), 
        0.0,
        2, 
        ShapeCore(floor_transform, Inv(floor_transform), true, false)
    )

    ceiling_transform = Translate(Pnt3(0,0,0))
    ceiling = Rectangle(
        Pnt2(-foyer_dim/2, -foyer_dim/2), 
        Pnt2(foyer_dim/2, foyer_dim/2), 
        ceiling_height,
        2, 
        ShapeCore(ceiling_transform, Inv(ceiling_transform), false, false)
    )

    pillar_1_t = Translate(Pnt3(0,0,0))
    pillar_1 = Box(
        Pnt3(-pillar_width_1, 0,             -pillar_width_2), 
        Pnt3(pillar_width_1,  ceiling_height, pillar_width_2), 
        ShapeCore(pillar_1_t, Inv(pillar_1_t), false, false)
    )
    pillar_2_t = RotateY(90.0)
    pillar_2 = Box(
        Pnt3(-pillar_width_1, 0,             -pillar_width_2), 
        Pnt3(pillar_width_1,  ceiling_height, pillar_width_2), 
        ShapeCore(pillar_2_t, Inv(pillar_2_t), false, false)
    )

    p_light_1_t = Translate(Pnt3(0,0,0))
    p_light_1 = Rectangle(
        Pnt2(5,  -pillar_width_2*.9), 
        Pnt2(50,  pillar_width_2*.9), 
        pillar_width_1,
        1, 
        ShapeCore(p_light_1_t, Inv(p_light_1_t), true, false)
    )

    p_light_2_t = Translate(Pnt3(0,0,0))
    p_light_2 = Rectangle(
        Pnt2(-pillar_width_2*.9, 5), 
        Pnt2(pillar_width_2*.9,  50), 
        pillar_width_1,
        3, 
        ShapeCore(p_light_2_t, Inv(p_light_2_t), true, false)
    )

    # vector of primitives & one for lights
    primitives = Primitive[]
    lights = Light[]    

    # add geometry
    for tri in vcat(floor, ceiling)
        push!(primitives, Primitive(tri, mat_concrete, nothing))
    end
    for tri in pillar_1
        push!(primitives, Primitive(tri, mat_blue, nothing))
    end
    for tri in pillar_2
        push!(primitives, Primitive(tri, mat_green, nothing))
    end

    for lit in vcat(p_light_1, p_light_2)      
        alight = DiffuseAreaLight(
            Spectrum(2500.0, 2500.0, 0),
            lit,
        )
        push!(lights, alight)
        push!(primitives, Primitive(lit, mat_white, alight))
    end

    # instantiate accelerator
    print("\nThere are " * num2str(length(primitives)) * " objects in the scene, building BVH\n")
    @time bvh = BVH(primitives)
    print("Done building BVH\n")

    # instantiate an env light
    env_light = InfinteLight(bvh, Translate(Vec3(0,0,0)), Translate(Vec3(0,0,0)), Spectrum(.5,.5,.5), "../ref/parking_lot.jpg")
    push!(lights, env_light)

    # print_BVH_bounds(BVH)

    # Instantiate a Filter
    filter = BoxFilter(Pnt2(.5, .5))

    # Instantiate a Film
    film = Film(
        Pnt2(250, 250),
        Bounds2(Pnt2(0,0), Pnt2(1,1)),
        filter,
        1.0,
        1.0,
        "yeehaw.png"
    )

    # Instantiate a Camera
    look_from = Pnt3(300, 100, 300)
    look_at = Pnt3(0, 0, 0)
    up = Vec3(0, -1, 0)
    screen = Bounds2(Pnt2(-1, -1), Pnt2(1, 1))
    C = PerspectiveCamera(LookAt(look_from, look_at, up), screen, 0.0, 1.0, 0.0, 1e6, 75.0, film)

    # Instantiate a Sampler
    S = StratifiedSampler(10, 10, 4, true)

    print("Using " * num2str(S.samples_per_pixel) * " samples per pixel\n")

    # Instantiate Scene
    scene = Scene(lights, bvh)
    
    # Instantiate an Integrator
    I = WhittedIntegrator(C, S, 25)

    render(I, scene)
end


@time test_integrate()

end
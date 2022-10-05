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

    ceiling_height = 200 # ~10ft * 20
    hallway_width = 160 # ~8ft * 20
    pillar_width_1 = 100 # ~5ft * 20
    pillar_width_2 = 30 # ~ 1.5ft * 20
    foyer_dim = 800 # ~30ft * 20
    ceiling_whole_size = 130 # ~6.5ft * 20
    ceiling_circle_thickness = 20 # ~1ft * 20
    ceiling_circle_offset = 10 # ~6in * 20
    pillar_alight_trim = 1

    ########################
    #### GEOMETRY ##########
    ########################

    floor_transform = Translate(Pnt3(0, 0, 0))
    floor = XZRectangle(
        floor_transform, 
        Pnt2(-foyer_dim/2, foyer_dim/2),
        Pnt2(-foyer_dim/2, foyer_dim/2),
        0.0,
        nothing,
        false,
        false
    )

    ceiling_transform = Translate(Pnt3(0,ceiling_height,0))
    ceiling = XZRectangle(
        ceiling_transform,
        Pnt2(-foyer_dim/2, foyer_dim/2),
        Pnt2(-foyer_dim/2, foyer_dim/2),
        0.0,
        CircleProceduralTexture(Pnt2(.5, .5), ceiling_whole_size * .98 / foyer_dim, Pnt3(1,1,1), Pnt3(0,0,0)), 
        true,
        false
    )

    pillar_transform = RotateY(-12.0)
    pillar1 = Box(
        pillar_transform,
        Pnt3(-pillar_width_1/2, -50, -pillar_width_2/2),
        Pnt3(pillar_width_1/2, 300, pillar_width_2/2),
        mat_blue
    )
    pillar2 = Box(
        pillar_transform,
        Pnt3(-pillar_width_2/2, -50, -pillar_width_1/2),
        Pnt3(pillar_width_2/2, 300, pillar_width_1/2),
        mat_green
    )

    pillar_alight_1 = YZRectangle(
        pillar_transform,
        # Ymin, Ymax 
        Pnt2(5, 50),                  
        # Xmin, Xmax
        Pnt2(-pillar_width_2/2 + 1, pillar_width_2/2-1),
        # Z
        pillar_width_1/2 + 1,                        
        nothing,
        true,
        false
    )

    ceiling_circle_t = Translate(Pnt3(0,ceiling_height - ceiling_circle_offset, 0))
    ceiling_circle_lip = Disk(
        ceiling_circle_t,
        0.0,                                 
        ceiling_whole_size * 1.0,
        (ceiling_whole_size - ceiling_circle_thickness)*1.0,
        360.0,
        true,
        false
    )
    ceiling_circle_inner = Cylindar(
        ceiling_circle_t,
        (ceiling_whole_size - ceiling_circle_thickness)*1.0,
        0.0,
        100.0,
        360.0,
        true,
        false
    )
    ceiling_circle_outer = Cylindar(
        ceiling_circle_t,
        ceiling_whole_size*1.0,
        0.0,
        100.0,
        360.0,
        false,
        false
    )

    # vector of primitives & one for lights
    primitives = Primitive[]
    lights = Light[]    

    # add box
    primitives = vcat(primitives, pillar1, pillar2)

    # add pillar lights
    pillar_alight_1_l = DiffuseAreaLight(
        Spectrum(50.0, 50.0, 50.0),
        pillar_alight_1
    )
    push!(lights, pillar_alight_1_l)
    push!(primitives, Primitive(pillar_alight_1, mat_red, pillar_alight_1_l))

    # add floor & ceiling
    push!(primitives, Primitive(floor, mat_concrete, nothing))
    push!(primitives, Primitive(ceiling, mat_concrete, nothing))

    # # add ceiling circle components
    push!(primitives, Primitive(ceiling_circle_lip, mat_red, nothing))
    push!(primitives, Primitive(ceiling_circle_inner, mat_red, nothing))
    push!(primitives, Primitive(ceiling_circle_outer, mat_red, nothing))

    # # instantiate area light ORBS
    # for t in [
    #     Translate(Pnt3(120, 100, 0)), 
    #     Translate(Pnt3(-120, 100, 0))
    # ]
    #     light_orb = Sphere(
    #         ShapeCore(t, Inv(t), false, false),
    #         20.0
    #     )
    #     area_light = DiffuseAreaLight(
    #         Spectrum(5.0, 5.0, 5.0),
    #         light_orb,
    #     )
    #     push!(lights, area_light)
    #     push!(primitives, Primitive(light_orb, mat_white, area_light))
    # end

    # instantiate accelerator
    print("\nThere are " * num2str(length(primitives)) * " objects in the scene, building BVH\n")
    @time bvh = BVH(primitives)
    print("Done building BVH\n")

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
    look_from = Pnt3(600, 100, 600)
    look_at = Pnt3(250, -100, 0) # TODO something is off here....
    up = Vec3(0, -1, 0)
    screen = Bounds2(Pnt2(-1, -1), Pnt2(1, 1))
    C = PerspectiveCamera(LookAt(look_from, look_at, up), screen, 0.0, 1.0, 0.0, 1e6, 175.5, film)

    # Instantiate a Sampler
    S = StratifiedSampler(4, 4, 4, true)

    print("Using " * num2str(S.samples_per_pixel) * " samples per pixel\n")

    # instantiate an env light
    env_light = InfinteLight(bvh, Translate(Vec3(0,0,0)), Translate(Vec3(0,0,0)), Spectrum(.5,.5,.5), "../ref/parking_lot.jpg")
    # push!(lights, env_light)

    # Instantiate Scene
    scene = Scene(lights, bvh)
    
    # Instantiate an Integrator
    I = WhittedIntegrator(C, S, 25)

    render(I, scene)
end


@time test_integrate()

end
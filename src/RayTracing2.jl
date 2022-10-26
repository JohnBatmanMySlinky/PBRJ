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

    ########################
    #### GEOMETRY ##########
    ########################
    floor_transform = Translate(Pnt3(0,0,0))
    floor = Rectangle(
        Pnt2(-foyer_dim/2, -foyer_dim/2), 
        Pnt2(foyer_dim/2, foyer_dim/2), 
        0.0,
        2, 
        ShapeCore(floor_transform, Inv(floor_transform), false, false),
        nothing
    )

    ceiling_transform = Translate(Pnt3(0,0,0))
    ceiling = Rectangle(
        Pnt2(-foyer_dim/2, -foyer_dim/2), 
        Pnt2(foyer_dim/2, foyer_dim/2), 
        ceiling_height,
        2, 
        ShapeCore(ceiling_transform, Inv(ceiling_transform), false, false),
        CircleProceduralTexture(
            Pnt2(.5, .5),
            ceiling_whole_size/foyer_dim,
            Spectrum(1,1,1),
            Spectrum(0,0,0)
        )
    )

    pillar_1_t = Translate(Pnt3(0,0,0))
    pillar_1 = Box(
        Pnt3(-pillar_width_1, 0,             -pillar_width_2), 
        Pnt3(pillar_width_1,  ceiling_height+300, pillar_width_2), 
        ShapeCore(pillar_1_t, Inv(pillar_1_t), false, false),
        nothing
    )
    pillar_2_t = RotateY(90.0)
    pillar_2 = Box(
        Pnt3(-pillar_width_1, 0,                  -pillar_width_2), 
        Pnt3(pillar_width_1,  ceiling_height+300, pillar_width_2), 
        ShapeCore(pillar_2_t, Inv(pillar_2_t), false, false),
        nothing
    )

    outer_cyl_t = RotateX(-90.0)
    outer_cyl = Cylindar(
        outer_cyl_t,
        ceiling_whole_size+ceiling_circle_thickness/2,
        ceiling_height-ceiling_circle_offset,
        ceiling_height+ceiling_circle_offset*50,
        360.0,
        false,
        false
    )
    inner_cyl_t = RotateX(-90.0)
    inner_cyl = Cylindar(
        inner_cyl_t,
        ceiling_whole_size-ceiling_circle_thickness/2,
        ceiling_height-ceiling_circle_offset,
        ceiling_height+ceiling_circle_offset*50,
        360.0,
        false,
        false
    )
    disk_t = RotateX(-90.0)
    disk = Disk(
        disk_t,
        ceiling_height-ceiling_circle_offset,
        ceiling_whole_size+ceiling_circle_thickness/2,
        ceiling_whole_size-ceiling_circle_thickness/2,
        360.0,
        false,
        false
    )

    p_light_1_t = Translate(Pnt3(0,0,0))
    p_light_1a = Rectangle(
        Pnt2(5,  -pillar_width_2+5), 
        Pnt2(55,  pillar_width_2-5), 
        pillar_width_1+.5,
        1, 
        ShapeCore(p_light_1_t, Inv(p_light_1_t), false, false),
        nothing
    )
    p_light_1b = Rectangle(
        Pnt2(60,  -pillar_width_2+5), 
        Pnt2(110,  pillar_width_2-5), 
        pillar_width_1+.5,
        1, 
        ShapeCore(p_light_1_t, Inv(p_light_1_t), false, false),
        nothing
    )
    p_light_1c = Rectangle(
        Pnt2(115,  -pillar_width_2+5), 
        Pnt2(165,   pillar_width_2-5), 
        pillar_width_1+.5,
        1, 
        ShapeCore(p_light_1_t, Inv(p_light_1_t), false, false),
        nothing
    )
    p_light_1d = Rectangle(
        Pnt2(170,  -pillar_width_2+5), 
        Pnt2(210,   pillar_width_2-5), 
        pillar_width_1+.5,
        1, 
        ShapeCore(p_light_1_t, Inv(p_light_1_t), false, false),
        nothing
    )
    p_light_1e = Rectangle(
        Pnt2(215,  -pillar_width_2+5), 
        Pnt2(265,   pillar_width_2-5), 
        pillar_width_1+.5,
        1, 
        ShapeCore(p_light_1_t, Inv(p_light_1_t), false, false),
        nothing
    )

    p_light_2_t = Translate(Pnt3(0,0,0))
    p_light_2a = Rectangle(
        Pnt2(-pillar_width_2+5, 5), 
        Pnt2( pillar_width_2-5,  55), 
        pillar_width_1+.5,
        3, 
        ShapeCore(p_light_2_t, Inv(p_light_2_t), false, false),
        nothing
    )
    p_light_2b = Rectangle(
        Pnt2(-pillar_width_2+5, 60), 
        Pnt2( pillar_width_2-5,  110), 
        pillar_width_1+.5,
        3, 
        ShapeCore(p_light_2_t, Inv(p_light_2_t), false, false),
        nothing
    )
    p_light_2c = Rectangle(
        Pnt2(-pillar_width_2+5, 115), 
        Pnt2( pillar_width_2-5,  165), 
        pillar_width_1+.5,
        3, 
        ShapeCore(p_light_2_t, Inv(p_light_2_t), false, false),
        nothing
    )
    p_light_2d = Rectangle(
        Pnt2(-pillar_width_2+5, 170), 
        Pnt2( pillar_width_2-5,  210), 
        pillar_width_1+.5,
        3, 
        ShapeCore(p_light_2_t, Inv(p_light_2_t), false, false),
        nothing
    )
    p_light_2e = Rectangle(
        Pnt2(-pillar_width_2+5, 215), 
        Pnt2( pillar_width_2-5,  265), 
        pillar_width_1+.5,
        3, 
        ShapeCore(p_light_2_t, Inv(p_light_2_t), false, false),
        nothing
    )

    p_light_3_t = Translate(Pnt3(0,0,0))
    p_light_3a = Rectangle(
        Pnt2(5,  -pillar_width_2+5), 
        Pnt2(55,  pillar_width_2-5), 
        -pillar_width_1-.5,
        1, 
        ShapeCore(p_light_3_t, Inv(p_light_3_t), true, false),
        nothing
    )
    p_light_3b = Rectangle(
        Pnt2(60,  -pillar_width_2+5), 
        Pnt2(110,  pillar_width_2-5), 
        -pillar_width_1-.5,
        1, 
        ShapeCore(p_light_3_t, Inv(p_light_3_t), true, false),
        nothing
    )
    p_light_3c = Rectangle(
        Pnt2(115,  -pillar_width_2+5), 
        Pnt2(165,   pillar_width_2-5), 
        -pillar_width_1-.5,
        1, 
        ShapeCore(p_light_3_t, Inv(p_light_3_t), true, false),
        nothing
    )
    p_light_3d = Rectangle(
        Pnt2(170,  -pillar_width_2+5), 
        Pnt2(210,   pillar_width_2-5), 
        -pillar_width_1-.5,
        1, 
        ShapeCore(p_light_3_t, Inv(p_light_3_t), true, false),
        nothing
    )
    p_light_3e = Rectangle(
        Pnt2(215,  -pillar_width_2+5), 
        Pnt2(265,   pillar_width_2-5), 
        -pillar_width_1-.5,
        1, 
        ShapeCore(p_light_3_t, Inv(p_light_3_t), true, false),
        nothing
    )

    p_light_4_t = Translate(Pnt3(0,0,0))
    p_light_4a = Rectangle(
        Pnt2(-pillar_width_2+5, 5), 
        Pnt2( pillar_width_2-5,  55), 
        -pillar_width_1-.5,
        3, 
        ShapeCore(p_light_4_t, Inv(p_light_4_t), true, false),
        nothing
    )
    p_light_4b = Rectangle(
        Pnt2(-pillar_width_2+5, 60), 
        Pnt2( pillar_width_2-5,  110), 
        -pillar_width_1-.5,
        3, 
        ShapeCore(p_light_4_t, Inv(p_light_4_t), true, false),
        nothing
    )
    p_light_4c = Rectangle(
        Pnt2(-pillar_width_2+5, 115), 
        Pnt2( pillar_width_2-5,  165), 
        -pillar_width_1-.5,
        3, 
        ShapeCore(p_light_4_t, Inv(p_light_4_t), true, false),
        nothing
    )
    p_light_4d = Rectangle(
        Pnt2(-pillar_width_2+5, 170), 
        Pnt2( pillar_width_2-5,  210), 
        -pillar_width_1-.5,
        3, 
        ShapeCore(p_light_4_t, Inv(p_light_4_t), true, false),
        nothing
    )
    p_light_4e = Rectangle(
        Pnt2(-pillar_width_2+5, 215), 
        Pnt2( pillar_width_2-5,  265), 
        -pillar_width_1-.5,
        3, 
        ShapeCore(p_light_4_t, Inv(p_light_4_t), true, false),
        nothing
    )

    # vector of primitives & one for lights
    primitives = Primitive[]
    lights = Light[]    

    # add geometry
    push!(primitives, Primitive(outer_cyl, mat_red, nothing))
    push!(primitives, Primitive(inner_cyl, mat_red, nothing))
    push!(primitives, Primitive(disk, mat_red, nothing))
    for tri in vcat(floor, ceiling)
        push!(primitives, Primitive(tri, mat_concrete, nothing))
    end
    # for tri in pillar_1
    #     push!(primitives, Primitive(tri, mat_blue, nothing))
    # end
    # for tri in pillar_2
    #     push!(primitives, Primitive(tri, mat_green, nothing))
    # end

    for lit in vcat(p_light_1a, p_light_1b, p_light_1c, p_light_1d, p_light_1e, p_light_2a, p_light_2b, p_light_2c, p_light_2d, p_light_2e, p_light_3a, p_light_3b, p_light_3c, p_light_3d, p_light_3e, p_light_4a, p_light_4b, p_light_4c, p_light_4d, p_light_4e)
        alight = DiffuseAreaLight(
            Spectrum(2500.0, 2500.0, 0),
            lit,
            false
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
    filter = BoxFilter(Pnt2(.1, .1))

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
    S = StratifiedSampler(4, 4, 4, true)

    print("Using " * num2str(S.samples_per_pixel) * " samples per pixel\n")

    # Instantiate Scene
    scene = Scene(lights, bvh)
    
    # Instantiate an Integrator
    I = WhittedIntegrator(C, S, 25)

    render(I, scene)
end


@time test_integrate()

end
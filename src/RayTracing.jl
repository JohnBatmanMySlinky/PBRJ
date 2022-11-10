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
include("filters/lanczos_sinc.jl")
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
include("materials/substrate.jl")
include("textures/constant.jl")
include("textures/image.jl")
include("textures/procedural.jl")
include("textures/mix.jl")
include("textures/noise.jl")
include("lights/light.jl")
include("lights/area.jl")
include("lights/point.jl")
include("lights/infinite.jl")
include("scene.jl")
include("integrators/whitted.jl")
include("handy_prints.jl")
include("obj_reader.jl")

function render_munich_re_scene(destination::String)
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
    mat_yellow = Matte(
        ConstantTexture(Vec3(1, 1, 0)),
        ConstantTexture(Vec3(0, 0, 0)),
        nothing
    )
    mat_concrete = Substrate(
        ImageTexture("../ref/Substance_Graph_BaseColor.jpg"), # kd
        ConstantTexture(Pnt3(.15, .15, .15)), # ks
        ConstantTexture(Pnt3(.003, .003, .003)), # u
        ConstantTexture(Pnt3(.003, .003, .003)), # v
        true, # remap
        ImageTexture("../ref/Substance_Graph_Height.jpg"), # kd
    )


    ###################################
    ###### GEOMETRICAL CONSTANTS ######
    ###################################

    ceiling_height = 200.0 # ~10ft * 20
    hallway_width = 160.0 # ~8ft * 20
    hallway_width_extra = 20.0
    pillar_width_1 = 60.0 # ~4.5ft * 20
    pillar_width_2 = 20.0 # ~ 1.5ft * 20
    foyer_dim = 600.0 # ~30ft * 20
    ceiling_whole_size = 130.0 # ~6.5ft * 20
    ceiling_circle_thickness = 20.0 # ~1ft * 20
    ceiling_circle_offset = 10.0 # ~6in * 20
    ceiling_circle_height = 250.0
    hallway_corner_offset = 240.0
    hallway_total_length = 1000.0

    ################# CORNER CONSTANTS
    edge_of_foyer = Pnt2(-foyer_dim/2, -foyer_dim/2)
    edge_of_back_right_wall = Pnt2(-foyer_dim/2+sqrt(hallway_corner_offset^2/2), -foyer_dim/2)
    edge_of_back_left_wall = Pnt2(-foyer_dim/2, -foyer_dim/2+sqrt(hallway_corner_offset^2/2))
    hallway_corner_tmp = sqrt(((hallway_corner_offset - hallway_width)/2)^2/2)
    hallway_corner_right = Pnt2(edge_of_back_right_wall.x - hallway_corner_tmp, edge_of_back_right_wall.y + hallway_corner_tmp)
    hallway_corner_left = Pnt2(edge_of_back_left_wall.x + hallway_corner_tmp, edge_of_back_left_wall.y - hallway_corner_tmp)
    hallway_corner_wall_right = Pnt2(
        (edge_of_back_right_wall.x + hallway_corner_right.x)/2,
        (edge_of_back_right_wall.y + hallway_corner_right.y)/2,
    )
    hallway_corner_wall_left = Pnt2(
        (edge_of_back_left_wall.x + hallway_corner_left.x)/2,
        (edge_of_back_left_wall.y + hallway_corner_left.y)/2,
    )
    hallway_walls_offset = sqrt((hallway_width/2)^2/2)
    hallway_centroid = Pnt2(
        (edge_of_back_right_wall.x + edge_of_back_left_wall.x)/2 - sqrt((hallway_total_length/2)^2/2),
        (edge_of_back_right_wall.y + edge_of_back_left_wall.y)/2 - sqrt((hallway_total_length/2)^2/2),
    )
    hallway_walls_adj = sqrt((hallway_width/2)^2/2)

    ceiling_floor_corner_alpha_mask_threshold = (edge_of_back_right_wall.x - -300)/600
    
    ##############################
    ##### Instantiating light & primitive vectors
    ##############################
    primitives = Primitive[]
    lights = Light[]
    primitives2 = Primitive[]
    lights2 = Light[]

    ########################
    #### GEOMETRY ##########
    ########################

    ################# FLOOR
    floor_transform = Translate(Pnt3(0,0,0))
    floor = Rectangle(
        Pnt2(-foyer_dim/2, -foyer_dim/2), 
        Pnt2(foyer_dim/2, foyer_dim/2), 
        0.0,
        2, 
        ShapeCore(floor_transform, Inv(floor_transform), false, false),
        CornerProceduralTexture(
            ceiling_floor_corner_alpha_mask_threshold,
            Spectrum(1,1,1),
            Spectrum(0,0,0),
        )
    )
    for tri in floor
        push!(primitives2, Primitive(tri, mat_concrete, nothing))
    end

    ################# CEILING
    ceiling_transform = Translate(Pnt3(0,0,0))
    ceiling = Rectangle(
        Pnt2(-foyer_dim/2, -foyer_dim/2), 
        Pnt2(foyer_dim/2, foyer_dim/2), 
        ceiling_height,
        2, 
        ShapeCore(ceiling_transform, Inv(ceiling_transform), false, false),
        MixAddTexture(
            CircleProceduralTexture(
                Pnt2(.5, .5),
                ceiling_whole_size/foyer_dim,
                Spectrum(1,1,1),
                Spectrum(0,0,0)
            ),
            CornerProceduralTexture(
                ceiling_floor_corner_alpha_mask_threshold,
                Spectrum(1,1,1),
                Spectrum(0,0,0),
            )
        )
    )
    for tri in ceiling
        push!(primitives, Primitive(tri, mat_white, nothing))
    end

    ################# RIGHT WALL
    rwall_transform = Translate(Pnt3(0,0,0))
    rwall = Rectangle(
        Pnt2(-foyer_dim/2 + sqrt(hallway_corner_offset^2/2), 0), 
        Pnt2(foyer_dim/2, ceiling_height), 
        -foyer_dim/2,
        3, 
        ShapeCore(rwall_transform, Inv(rwall_transform), false, false),
        nothing
    )
    for tri in rwall
        push!(primitives, Primitive(tri, mat_white, nothing))
    end

    ################# LEFT WALL
    lwall_transform = Translate(Pnt3(0,0,0))
    lwall = Rectangle(
        Pnt2(0, -foyer_dim/2+sqrt(hallway_corner_offset^2/2)), 
        Pnt2(ceiling_height, foyer_dim/2), 
        -foyer_dim/2,
        1, 
        ShapeCore(lwall_transform, Inv(lwall_transform), false, false),
        nothing
    )
    for tri in lwall
        push!(primitives, Primitive(tri, mat_white, nothing))
    end

    ################# Pillar 1
    pillar_1_t = Translate(Pnt3(0,0,0))
    pillar_1 = Box(
        Pnt3(-pillar_width_1, 0,             -pillar_width_2), 
        Pnt3(pillar_width_1,  ceiling_circle_height, pillar_width_2), 
        ShapeCore(pillar_1_t, Inv(pillar_1_t), false, false),
        nothing
    )
    for tri in pillar_1
        push!(primitives, Primitive(tri, mat_white, nothing))
    end

    ################# Pillar 2
    pillar_2_t = RotateY(90.0)
    pillar_2 = Box(
        Pnt3(-pillar_width_1, 0,                  -pillar_width_2), 
        Pnt3(pillar_width_1,  ceiling_circle_height, pillar_width_2), 
        ShapeCore(pillar_2_t, Inv(pillar_2_t), false, false),
        nothing
    )
    for tri in pillar_2
        push!(primitives, Primitive(tri, mat_white, nothing))
    end

    ################# CEILING CYLINDAR
    outer_cyl_t = RotateX(-90.0)
    outer_cyl = Cylindar(
        outer_cyl_t,
        ceiling_whole_size+ceiling_circle_thickness/2,
        ceiling_height-ceiling_circle_offset,
        ceiling_circle_height,
        360.0,
        false,
        false
    )
    inner_cyl_t = RotateX(-90.0)
    inner_cyl = Cylindar(
        inner_cyl_t,
        ceiling_whole_size-ceiling_circle_thickness/2,
        ceiling_height-ceiling_circle_offset,
        ceiling_circle_height,
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
    push!(primitives, Primitive(outer_cyl, mat_white, nothing))
    push!(primitives, Primitive(inner_cyl, mat_white, nothing))
    push!(primitives, Primitive(disk, mat_white, nothing))

    ################# Pillar Area Lights
    MULT = 500
    yellow = Spectrum(1.0, 1.0, 0.0)
    white = Spectrum(1.0, 1.0, 1.0)
    blue = Spectrum(0.0, 0.0, 1.0)
    red = Spectrum(1.0, 0.0, 0.0)
    pink = Spectrum(1.0, 0.0, 1.0)
    green = Spectrum(0.0, 1.0, 0.0)
    pillar_area_light_spec = Tuple{Pnt2, Pnt2, Float64, Int64, Spectrum, Bool}[
        (Pnt2(5,    -pillar_width_2+5), Pnt2(55,   pillar_width_2-5), pillar_width_1+.5, 1, yellow, false),
        (Pnt2(60,   -pillar_width_2+5), Pnt2(110,  pillar_width_2-5), pillar_width_1+.5, 1, white, false),
        (Pnt2(115,  -pillar_width_2+5), Pnt2(165,  pillar_width_2-5), pillar_width_1+.5, 1, pink, false),
        (Pnt2(170,  -pillar_width_2+5), Pnt2(210,  pillar_width_2-5), pillar_width_1+.5, 1, blue, false),
        (Pnt2(215,  -pillar_width_2+5), Pnt2(265,  pillar_width_2-5), pillar_width_1+.5, 1, red, false),

        (Pnt2(-pillar_width_2+5, 5),   Pnt2(pillar_width_2-5, 55),  pillar_width_1+.5, 3, white, false),
        (Pnt2(-pillar_width_2+5, 60),  Pnt2(pillar_width_2-5, 110), pillar_width_1+.5, 3, blue, false),
        (Pnt2(-pillar_width_2+5, 115), Pnt2(pillar_width_2-5, 165), pillar_width_1+.5, 3, red, false),
        (Pnt2(-pillar_width_2+5, 170), Pnt2(pillar_width_2-5, 210), pillar_width_1+.5, 3, pink, false),
        (Pnt2(-pillar_width_2+5, 215), Pnt2(pillar_width_2-5, 265), pillar_width_1+.5, 3, green, false),

        (Pnt2(5,    -pillar_width_2+5), Pnt2(55,   pillar_width_2-5), -pillar_width_1-.5, 1, yellow, true),
        (Pnt2(60,   -pillar_width_2+5), Pnt2(110,  pillar_width_2-5), -pillar_width_1-.5, 1, white, true),
        (Pnt2(115,  -pillar_width_2+5), Pnt2(165,  pillar_width_2-5), -pillar_width_1-.5, 1, pink, true),
        (Pnt2(170,  -pillar_width_2+5), Pnt2(210,  pillar_width_2-5), -pillar_width_1-.5, 1, blue, true),
        (Pnt2(215,  -pillar_width_2+5), Pnt2(265,  pillar_width_2-5), -pillar_width_1-.5, 1, red, true),

        (Pnt2(-pillar_width_2+5, 5),   Pnt2(pillar_width_2-5, 55),  -pillar_width_1-.5, 3, white, true),
        (Pnt2(-pillar_width_2+5, 60),  Pnt2(pillar_width_2-5, 110), -pillar_width_1-.5, 3, blue, true),
        (Pnt2(-pillar_width_2+5, 115), Pnt2(pillar_width_2-5, 165), -pillar_width_1-.5, 3, red, true),
        (Pnt2(-pillar_width_2+5, 170), Pnt2(pillar_width_2-5, 210), -pillar_width_1-.5, 3, pink, true),
        (Pnt2(-pillar_width_2+5, 215), Pnt2(pillar_width_2-5, 265), -pillar_width_1-.5, 3, green, true),
    ]

    t = Translate(Pnt3(0,0,0))
    for (pmin, pmax, k, axis, brightness, flip) in pillar_area_light_spec
        tmp_rec = Rectangle(
            pmin, 
            pmax, 
            k,
            axis, 
            ShapeCore(t, Inv(t), flip, false),
            nothing
        )
        mat_tmp = Matte(
            ConstantTexture(brightness),
            ConstantTexture(Vec3(0, 0, 0)),
            nothing
        )
        for tri in tmp_rec
            alight = DiffuseAreaLight(
                brightness*MULT,
                tri,
                false
            )
            push!(lights, alight)
            push!(primitives, Primitive(tri, mat_tmp, alight))
        end
    end

    ################# CORNER WALLS
    lcwall_transform = Translate(Pnt3(hallway_corner_wall_left.x,0,hallway_corner_wall_left.y))*RotateY(45.0)
    lcwall = Rectangle(
        Pnt2(-40, 0), 
        Pnt2(40, ceiling_height), 
        0.0,
        3, 
        ShapeCore(lcwall_transform, Inv(lcwall_transform), false, false),
        nothing
    )
    for tri in lcwall
        push!(primitives, Primitive(tri, mat_white, nothing))
    end
    rcwall_transform = Translate(Pnt3(hallway_corner_wall_right.x,0,hallway_corner_wall_right.y))*RotateY(45.0)
    rcwall = Rectangle(
        Pnt2(-40, 0), 
        Pnt2(40, ceiling_height), 
        0.0,
        3, 
        ShapeCore(rcwall_transform, Inv(rcwall_transform), false, false),
        nothing
    )
    for tri in rcwall
        push!(primitives, Primitive(tri, mat_white, nothing))
    end


    ################# HALLWAY
    rhwall_transform = Translate(Pnt3(hallway_centroid.x+hallway_walls_adj,0,hallway_centroid.y-hallway_walls_adj)) * RotateY(-45.0)
    rhwall = Rectangle(
        Pnt2(-hallway_total_length/2, hallway_width_extra), 
        Pnt2(hallway_total_length/2, ceiling_height), 
        0.0,
        3, 
        ShapeCore(rhwall_transform, Inv(rhwall_transform), false, false),
        nothing
    )
    for tri in rhwall
        push!(primitives, Primitive(tri, mat_white, nothing))
    end
    extra_hallway_walls_adj = sqrt((hallway_width/2+hallway_width_extra)^2/2)
    rh_extra_wall_transform = Translate(Pnt3(hallway_centroid.x+extra_hallway_walls_adj,0,hallway_centroid.y-extra_hallway_walls_adj)) * RotateY(-45.0)
    rh_extra_wall = Rectangle(
        Pnt2(-hallway_total_length/2, 0), 
        Pnt2(hallway_total_length/2, hallway_width_extra), 
        0.0,
        3, 
        ShapeCore(rh_extra_wall_transform, Inv(rh_extra_wall_transform), false, false),
        nothing
    )
    for tri in rh_extra_wall
        push!(primitives, Primitive(tri, mat_white, nothing))
    end
    lhwall_transform = Translate(Pnt3(hallway_centroid.x-hallway_walls_adj,0,hallway_centroid.y+hallway_walls_adj)) * RotateY(-45.0)
    lhwall = Rectangle(
        Pnt2(-hallway_total_length/2, 0), 
        Pnt2(hallway_total_length/2, ceiling_height), 
        0.0,
        3, 
        ShapeCore(lhwall_transform, Inv(lhwall_transform), false, false),
        nothing
    )
    for tri in lhwall
        push!(primitives, Primitive(tri, mat_white, nothing))
    end
    cewall_transform = Translate(Pnt3(hallway_centroid.x,0,hallway_centroid.y)) * RotateY(-45.0)
    cewall = Rectangle(
        Pnt2(-hallway_total_length/2, -hallway_width/2), 
        Pnt2(hallway_total_length/2, hallway_width/2), 
        ceiling_height,
        2, 
        ShapeCore(cewall_transform, Inv(cewall_transform), false, false),
        nothing
    )
    for tri in cewall
        push!(primitives, Primitive(tri, mat_white, nothing))
    end
    flwall_transform = Translate(Pnt3(hallway_centroid.x,0,hallway_centroid.y)) * RotateY(-45.0)
    flwall = Rectangle(
        Pnt2(-hallway_total_length/2, -hallway_width/2-hallway_width_extra), 
        Pnt2(hallway_total_length/2, hallway_width/2), 
        0.0,
        2, 
        ShapeCore(flwall_transform, Inv(flwall_transform), false, false),
        nothing
    )
    for tri in flwall
        push!(primitives, Primitive(tri, mat_concrete, nothing))
    end

    # hallway floor area light
    hallway_light_transform = Translate(Pnt3(hallway_centroid.x,0,hallway_centroid.y)) * RotateY(-45.0)
    hallway_light = Rectangle(
        Pnt2(-hallway_total_length/2, -hallway_width/2-hallway_width_extra), 
        Pnt2(hallway_total_length/2, -hallway_width/2-1), 
        hallway_width_extra,
        2, 
        ShapeCore(hallway_light_transform, Inv(hallway_light_transform), false, false),
        nothing
    )
    for tri in hallway_light
        alight = DiffuseAreaLight(
            Spectrum(10000, 10000, 10000),
            tri,
            false
        )
        push!(lights, alight)
        push!(primitives, Primitive(tri, mat_white, alight))
    end
    
    # instantiate accelerator
    print("\nThere are " * num2str(length(primitives2)) * " objects in the scene, building BVH\n")
    @time bvh = BVH(primitives2)
    print("Done building BVH\n")

    # instantiate an env light
    env_light = InfinteLight(bvh, Translate(Vec3(0,0,0)), Translate(Vec3(0,0,0)), Spectrum(1, 1, 1), "../ref/parking_lot.jpg")
    push!(lights2, env_light)

    # Instantiate a Filter
    filter = BoxFilter(Pnt2(.1, .1))

    # Instantiate a Film
    film = Film(
        Pnt2(500, 500),
        Bounds2(Pnt2(0,0), Pnt2(1,1)),
        filter,
        1.0,
        1.0,
        destination
    )

    # Instantiate a Camera
    look_from = Pnt3(150, 120, 400)
    look_at = Pnt3(0, 100, 0)
    up = Vec3(0, -1, 0)
    screen = Bounds2(Pnt2(-1, -1), Pnt2(1, 1))
    C = PerspectiveCamera(LookAt(look_from, look_at, up), screen, 0.0, 1.0, 0.0, 1e6, 65.0, film)

    # Instantiate a Sampler
    S = StratifiedSampler(25, 25, 4, true)
    print("Using " * num2str(S.samples_per_pixel) * " samples per pixel\n")
    
    # Instantiate Scene
    scene = Scene(lights2, bvh)
    
    # Instantiate an Integrator
    I = WhittedIntegrator(C, S, 50)

    render(I, scene, false)
end

end
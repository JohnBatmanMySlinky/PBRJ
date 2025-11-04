function make_scene1(parsed_args::Dict)::Tuple{AbstractIntegrator, Scene}
    ###########################
    ######## Materials ########
    ###########################
    materials = Material[]
    mat_white = Matte(
        "mat_white",
        ConstantTexture(spectrum_from_float(1.0, 1.0, 1.0)),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_white)

    mat_red = Matte(
        "mat_red",
        ConstantTexture(spectrum_from_float(1.0, 0.0, 0.0)),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_red)

    mat_green = Matte(
        "mat_green",
        ConstantTexture(spectrum_from_float(0.0, 1.0, 0.0)),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_green)

    mat_blue = Matte(
        "mat_blue",
        ConstantTexture(spectrum_from_float(0.0, 0.0, 1.0)),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_blue)

    mat_yellow = Matte(
        "mat_yellow",
        ConstantTexture(spectrum_from_float(1.0, 1.0, 0.0)),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_yellow)

    mat_gray = Matte(
        "mat_gray",
        ConstantTexture(spectrum_from_float(1.0, 1.0, 0.0)),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_gray)

    mat_concrete = Substrate(
        "mat_concrete",
        ImageTexture(
            UVMapping2D(), 
            jmfp("/Users/johnmyslinski/Documents/PBRJ/ref/Substance_Graph_BaseColor.jpg"), 
            false
        ), # kd
        ConstantTexture(spectrum_from_float(0.15, 0.15, 0.15)), # ks
        ConstantTexture(.003), # u
        ConstantTexture(.003), # v
        ImageTexture(
            UVMapping2D(), 
            jmfp("/Users/johnmyslinski/Documents/PBRJ/ref/Substance_Graph_Height.jpg"),
            true
        ), # bumo
        true # remap
    )
    push!(materials, mat_concrete)

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

    ceiling_floor_corner_alpha_mask_threshold = (edge_of_back_right_wall.x - -300.0)/600.0

    ###########################
    ######## Textures ########
    ###########################

    textures = AbstractTexture[]

    tex_floor_corner = CornerProceduralTexture(
        ceiling_floor_corner_alpha_mask_threshold,
        1.0,
        0.0,
        "tex_floor_corner"
    )
    push!(textures, tex_floor_corner)

    tex_ceiling = MixAddTexture(
        CircleProceduralTexture(
            Pnt2(.5, .5),
            ceiling_whole_size/foyer_dim,
            1.0,
            0.0,
            nothing
        ),
        CornerProceduralTexture(
            ceiling_floor_corner_alpha_mask_threshold,
            1.0,
            0.0,
            nothing
        ),
        "tex_ceiling"
    )
    push!(textures, tex_ceiling)
    
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
        false,
        "tex_floor_corner"
    )
    for tri in floor
        push!(primitives, Primitive(tri, "mat_concrete", nothing))
    end
    for tri in floor
        push!(primitives2, Primitive(tri, "mat_red", nothing))
    end

    ################# CEILING
    ceiling_transform = Translate(Pnt3(0,0,0))
    ceiling = Rectangle(
        Pnt2(-foyer_dim/2, -foyer_dim/2), 
        Pnt2(foyer_dim/2, foyer_dim/2), 
        ceiling_height,
        2, 
        ShapeCore(ceiling_transform, Inv(ceiling_transform), true, false),
        false,
        "tex_ceiling"
    )
    for tri in ceiling
        push!(primitives, Primitive(tri, "mat_white", nothing))
    end

    ################# RIGHT WALL
    rwall_transform = Translate(Pnt3(0,0,0))
    rwall = Rectangle(
        Pnt2(-foyer_dim/2 + sqrt(hallway_corner_offset^2/2), 0), 
        Pnt2(foyer_dim/2, ceiling_height), 
        -foyer_dim/2,
        3, 
        ShapeCore(rwall_transform, Inv(rwall_transform), false, false),
        false,
        nothing
    )
    for tri in rwall
        push!(primitives, Primitive(tri, "mat_white", nothing))
    end

    ################# LEFT WALL
    lwall_transform = Translate(Pnt3(0,0,0))
    lwall = Rectangle(
        Pnt2(0, -foyer_dim/2+sqrt(hallway_corner_offset^2/2)), 
        Pnt2(ceiling_height, foyer_dim/2), 
        -foyer_dim/2,
        1, 
        ShapeCore(lwall_transform, Inv(lwall_transform), false, false),
        false,
        nothing
    )
    for tri in lwall
        push!(primitives, Primitive(tri, "mat_white", nothing))
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
        push!(primitives, Primitive(tri, "mat_white", nothing))
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
        push!(primitives, Primitive(tri, "mat_white", nothing))
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
        true,
        false
    )
    disk_t = RotateX(-90.0)
    disk = Disk(
        disk_t,
        ceiling_height-ceiling_circle_offset,
        ceiling_whole_size+ceiling_circle_thickness/2,
        ceiling_whole_size-ceiling_circle_thickness/2,
        360.0,
        true,
        false
    )
    push!(primitives, Primitive(outer_cyl, "mat_white", nothing))
    push!(primitives, Primitive(inner_cyl, "mat_white", nothing))
    push!(primitives, Primitive(disk, "mat_white", nothing))

    ################# Pillar Area Lights
    MULT = 5
    yellow = spectrum_from_float(1.0, 1.0, 0.0)
    white = spectrum_from_float(1.0, 1.0, 1.0)
    blue = spectrum_from_float(0.0, 0.0, 1.0)
    red = spectrum_from_float(1.0, 0.0, 0.0)
    pink = spectrum_from_float(1.0, 0.0, 1.0)
    green = spectrum_from_float(0.0, 1.0, 0.0)
    pillar_area_light_spec = Tuple{Pnt2, Pnt2, Float64, Int64, Spectrum, String, Bool}[
        (Pnt2(5,    -pillar_width_2+5), Pnt2(55,   pillar_width_2-5), pillar_width_1+.5, 1, yellow, "yellow", false),
        (Pnt2(60,   -pillar_width_2+5), Pnt2(110,  pillar_width_2-5), pillar_width_1+.5, 1, white, "white", false),
        (Pnt2(115,  -pillar_width_2+5), Pnt2(165,  pillar_width_2-5), pillar_width_1+.5, 1, pink, "pink", false),
        (Pnt2(170,  -pillar_width_2+5), Pnt2(210,  pillar_width_2-5), pillar_width_1+.5, 1, blue, "blue", false),
        (Pnt2(215,  -pillar_width_2+5), Pnt2(265,  pillar_width_2-5), pillar_width_1+.5, 1, red, "red", false),

        (Pnt2(-pillar_width_2+5, 5),   Pnt2(pillar_width_2-5, 55),  pillar_width_1+.5, 3, white, "white", false),
        (Pnt2(-pillar_width_2+5, 60),  Pnt2(pillar_width_2-5, 110), pillar_width_1+.5, 3, blue, "blue", false),
        (Pnt2(-pillar_width_2+5, 115), Pnt2(pillar_width_2-5, 165), pillar_width_1+.5, 3, red, "red", false),
        (Pnt2(-pillar_width_2+5, 170), Pnt2(pillar_width_2-5, 210), pillar_width_1+.5, 3, pink, "pink", false),
        (Pnt2(-pillar_width_2+5, 215), Pnt2(pillar_width_2-5, 265), pillar_width_1+.5, 3, green, "green", false),

        (Pnt2(5,    -pillar_width_2+5), Pnt2(55,   pillar_width_2-5), -pillar_width_1-.5, 1, yellow, "yellow", true),
        (Pnt2(60,   -pillar_width_2+5), Pnt2(110,  pillar_width_2-5), -pillar_width_1-.5, 1, white, "white", true),
        (Pnt2(115,  -pillar_width_2+5), Pnt2(165,  pillar_width_2-5), -pillar_width_1-.5, 1, pink, "pink", true),
        (Pnt2(170,  -pillar_width_2+5), Pnt2(210,  pillar_width_2-5), -pillar_width_1-.5, 1, blue, "blue", true),
        (Pnt2(215,  -pillar_width_2+5), Pnt2(265,  pillar_width_2-5), -pillar_width_1-.5, 1, red, "red", true),

        (Pnt2(-pillar_width_2+5, 5),   Pnt2(pillar_width_2-5, 55),  -pillar_width_1-.5, 3, white, "white", true),
        (Pnt2(-pillar_width_2+5, 60),  Pnt2(pillar_width_2-5, 110), -pillar_width_1-.5, 3, blue, "blue", true),
        (Pnt2(-pillar_width_2+5, 115), Pnt2(pillar_width_2-5, 165), -pillar_width_1-.5, 3, red, "red", true),
        (Pnt2(-pillar_width_2+5, 170), Pnt2(pillar_width_2-5, 210), -pillar_width_1-.5, 3, pink, "pink", true),
        (Pnt2(-pillar_width_2+5, 215), Pnt2(pillar_width_2-5, 265), -pillar_width_1-.5, 3, green, "green", true),
    ]

    t = Translate(Pnt3(0,0,0))
    for (i, (pmin, pmax, k, axis, brightness, mat_name, flip)) in enumerate(pillar_area_light_spec)
        tmp_rec = Rectangle(
            pmin, 
            pmax, 
            k,
            axis, 
            ShapeCore(t, Inv(t), flip, false),
            false,
            nothing
        )
        mat_tmp = Matte(
            "mat_tmp_" * mat_name,
            ConstantTexture(brightness),
            ConstantTexture(0.0),
            nothing
        )
        push!(materials, mat_tmp)
        
        for tri in tmp_rec
            alight = DiffuseAreaLight(
                brightness*MULT,
                tri,
                false
            )
            push!(lights, alight)
            push!(primitives, Primitive(tri, "mat_tmp_" * mat_name, alight))
        end
        if (i == 6) || (i == 7) || (i == 8) || (i == 9) || (i == 10)
            for tri in tmp_rec
                alight = DiffuseAreaLight(
                    brightness*MULT,
                    tri,
                    false
                )
                push!(lights2, alight)
                push!(primitives2, Primitive(tri, "mat_tmp", alight))
            end
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
        false,
        nothing
    )
    for tri in lcwall
        push!(primitives, Primitive(tri, "mat_white", nothing))
    end
    rcwall_transform = Translate(Pnt3(hallway_corner_wall_right.x,0,hallway_corner_wall_right.y))*RotateY(45.0)
    rcwall = Rectangle(
        Pnt2(-40, 0), 
        Pnt2(40, ceiling_height), 
        0.0,
        3, 
        ShapeCore(rcwall_transform, Inv(rcwall_transform), false, false),
        false,
        nothing
    )
    for tri in rcwall
        push!(primitives, Primitive(tri, "mat_white", nothing))
    end


    ################# HALLWAY
    rhwall_transform = Translate(Pnt3(hallway_centroid.x+hallway_walls_adj,0,hallway_centroid.y-hallway_walls_adj)) * RotateY(-45.0)
    rhwall = Rectangle(
        Pnt2(-hallway_total_length/2, hallway_width_extra), 
        Pnt2(hallway_total_length/2, ceiling_height), 
        0.0,
        3, 
        ShapeCore(rhwall_transform, Inv(rhwall_transform), false, false),
        false,
        nothing
    )
    for tri in rhwall
        push!(primitives, Primitive(tri, "mat_white", nothing))
    end
    extra_hallway_walls_adj = sqrt((hallway_width/2+hallway_width_extra)^2/2)
    rh_extra_wall_transform = Translate(Pnt3(hallway_centroid.x+extra_hallway_walls_adj,0,hallway_centroid.y-extra_hallway_walls_adj)) * RotateY(-45.0)
    rh_extra_wall = Rectangle(
        Pnt2(-hallway_total_length/2, 0), 
        Pnt2(hallway_total_length/2, hallway_width_extra), 
        0.0,
        3, 
        ShapeCore(rh_extra_wall_transform, Inv(rh_extra_wall_transform), false, false),
        false,
        nothing
    )
    for tri in rh_extra_wall
        push!(primitives, Primitive(tri, "mat_white", nothing))
    end
    lhwall_transform = Translate(Pnt3(hallway_centroid.x-hallway_walls_adj,0,hallway_centroid.y+hallway_walls_adj)) * RotateY(-45.0)
    lhwall = Rectangle(
        Pnt2(-hallway_total_length/2, 0), 
        Pnt2(hallway_total_length/2, ceiling_height), 
        0.0,
        3, 
        ShapeCore(lhwall_transform, Inv(lhwall_transform), false, false),
        false,
        nothing
    )
    for tri in lhwall
        push!(primitives, Primitive(tri, "mat_white", nothing))
    end
    cewall_transform = Translate(Pnt3(hallway_centroid.x,0,hallway_centroid.y)) * RotateY(-45.0)
    cewall = Rectangle(
        Pnt2(-hallway_total_length/2, -hallway_width/2), 
        Pnt2(hallway_total_length/2, hallway_width/2), 
        ceiling_height,
        2, 
        ShapeCore(cewall_transform, Inv(cewall_transform), true, false),
        false,
        nothing
    )
    for tri in cewall
        push!(primitives, Primitive(tri, "mat_white", nothing))
    end
    flwall_transform = Translate(Pnt3(hallway_centroid.x,0,hallway_centroid.y)) * RotateY(-45.0)
    flwall = Rectangle(
        Pnt2(-hallway_total_length/2, -hallway_width/2-hallway_width_extra), 
        Pnt2(hallway_total_length/2, hallway_width/2), 
        0.0,
        2, 
        ShapeCore(flwall_transform, Inv(flwall_transform), false, false),
        false,
        nothing
    )
    for tri in flwall
        push!(primitives, Primitive(tri, "mat_concrete", nothing))
    end

    # hallway floor area light
    hallway_light_transform = Translate(Pnt3(hallway_centroid.x,0,hallway_centroid.y)) * RotateY(-45.0)
    hallway_light = Rectangle(
        Pnt2(-hallway_total_length/2, -hallway_width/2-hallway_width_extra), 
        Pnt2(hallway_total_length/2, -hallway_width/2-1), 
        hallway_width_extra,
        2, 
        ShapeCore(hallway_light_transform, Inv(hallway_light_transform), false, false),
        false,
        nothing
    )
    for tri in hallway_light
        alight = DiffuseAreaLight(
            spectrum_from_float(5.0, 5.0, 5.0),
            tri,
            false
        )
        push!(lights, alight)
        push!(primitives, Primitive(tri, "mat_white", alight))
    end

    name_index = Dict(mat.name => i for (i, mat) in enumerate(materials))
    MATERIAL_REGISTRY[] = MaterialRegistry(materials, name_index)

    name_index = Dict(mat.name => i for (i, mat) in enumerate(textures))
    ALPHA_TEXTURE_REGISTRY[] = AlphaTextureRegistry(textures, name_index)
    
    # instantiate accelerator
    print("\nThere are " * num2str(length(primitives)) * " objects in the scene, building BVH\n")
    @time bvh = BVH(primitives)
    print("Done building BVH\n")

    # Instantiate a Filter
    filter = BoxFilter(Pnt2(.5, .5))

    # Instantiate a Film
    film = Film(
        Pnt2i(parsed_args["image-dim"][1], parsed_args["image-dim"][2]),
        Bounds2(Pnt2(0,0), Pnt2(1,1)),
        filter,
        1.0,
        1.0,
        parsed_args["file-name"]
    )

    # Instantiate a Camera
    look_from = Pnt3(150, 120, 400)
    look_at = Pnt3(0, 100, 0)
    up = Vec3(0, 1, 0)
    C = PerspectiveCamera(LookAt(look_from, look_at, up), 0.0, 1.0, 0.0, 1e6, 65.0, film)

    # Instantiate a Sampler
    S = SamplerFactory(parsed_args)
    print("Using " * num2str(S.samples_per_pixel) * " samples per pixel\n")
    
    # Instantiate Scene
    print("There are " * num2str(length(lights)) * " lights in the scene\n")
    scene = Scene(lights, bvh)
    
    # Instantiate an Integrator
    I = BDPTIntegrator(C, S, parsed_args["max-depth"])

    return I, scene
end
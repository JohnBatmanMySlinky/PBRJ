"""
scene 1: indoor office ✅
scene 2: caustic glass 🟨
scene 3: AOIntegrator + dragon ✅
scene 4: cornell box ✅
scene 5: soft bodies ✅
scene 6: goursat ✅
scene 7: julia logo ✅
scene 8: an anemic leafless procedural tree ✅
scene 9: a broken ass orb 🔴
scene 10: a cloud ✅
scene 11: infinite light show off & material testing 🟨
"""

function build_scene(parsed_args::Dict)::Tuple{AbstractIntegrator, Scene}
    if parsed_args["scene-number"] == 1
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
        mat_gray = Matte(
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
            false,
            CornerProceduralTexture(
                ceiling_floor_corner_alpha_mask_threshold,
                spectrum_from_float(1.0),
                spectrum_from_float(0.0),
            )
        )
        for tri in floor
            push!(primitives, Primitive(tri, mat_concrete, nothing))
        end
        for tri in floor
            push!(primitives2, Primitive(tri, mat_red, nothing))
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
            MixAddTexture(
                CircleProceduralTexture(
                    Pnt2(.5, .5),
                    ceiling_whole_size/foyer_dim,
                    spectrum_from_float(1.0),
                    spectrum_from_float(0.0)
                ),
                CornerProceduralTexture(
                    ceiling_floor_corner_alpha_mask_threshold,
                    spectrum_from_float(1.0),
                    spectrum_from_float(0.0),
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
            false,
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
            false,
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
        push!(primitives, Primitive(outer_cyl, mat_white, nothing))
        push!(primitives, Primitive(inner_cyl, mat_white, nothing))
        push!(primitives, Primitive(disk, mat_white, nothing))

        ################# Pillar Area Lights
        MULT = 5
        yellow = spectrum_from_float(1.0, 1.0, 0.0)
        white = spectrum_from_float(1.0, 1.0, 1.0)
        blue = spectrum_from_float(0.0, 0.0, 1.0)
        red = spectrum_from_float(1.0, 0.0, 0.0)
        pink = spectrum_from_float(1.0, 0.0, 1.0)
        green = spectrum_from_float(0.0, 1.0, 0.0)
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
        for (i, (pmin, pmax, k, axis, brightness, flip)) in enumerate(pillar_area_light_spec)
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
            if (i == 6) || (i == 7) || (i == 8) || (i == 9) || (i == 10)
                for tri in tmp_rec
                    alight = DiffuseAreaLight(
                        brightness*MULT,
                        tri,
                        false
                    )
                    push!(lights2, alight)
                    push!(primitives2, Primitive(tri, mat_tmp, alight))
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
            push!(primitives, Primitive(tri, mat_white, nothing))
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
            false,
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
            false,
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
            false,
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
            ShapeCore(cewall_transform, Inv(cewall_transform), true, false),
            false,
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
            false,
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
            push!(primitives, Primitive(tri, mat_white, alight))
        end
        
        # instantiate accelerator
        print("\nThere are " * num2str(length(primitives)) * " objects in the scene, building BVH\n")
        @time bvh = BVH(primitives)
        print("Done building BVH\n")

        # Instantiate a Filter
        filter = BoxFilter(Pnt2(.5, .5))

        # Instantiate a Film
        film = Film(
            Pnt2(parsed_args["image-dim"], parsed_args["image-dim"]),
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
        screen = Bounds2(Pnt2(-1, -1), Pnt2(1, 1))
        C = PerspectiveCamera(LookAt(look_from, look_at, up), screen, 0.0, 1.0, 0.0, 1e6, 65.0, film)

        # Instantiate a Sampler
        S = StratifiedSampler(parsed_args["samples-per-pixel"], true)
        print("Using " * num2str(S.samples_per_pixel) * " samples per pixel\n")
        
        # Instantiate Scene
        print("There are " * num2str(length(lights)) * " lights in the scene\n")
        scene = Scene(lights, bvh)
        
        # Instantiate an Integrator
        I = BDPTIntegrator(C, S, parsed_args["max-depth"])

        return I, scene
    elseif parsed_args["scene-number"] == 2
        primitives = Primitive[]
        lights = Light[]

        mat_gray = Matte(
            ConstantTexture(Vec3(.4, .4, .4)),
            ConstantTexture(Vec3(0, 0, 0)),
            nothing
        )
        mat_white = Matte(
            ConstantTexture(Vec3(1.0, 1.0, 1.0)),
            ConstantTexture(Vec3(0, 0, 0)),
            nothing
        )
        mat_glass = Glass(
            ConstantTexture(Pnt3(.85, .85, 1.0)),
            ConstantTexture(Pnt3(.85, .85, 1.0)),
            ConstantTexture(Pnt3(0.0)),
            ConstantTexture(Pnt3(0.0)),
            ConstantTexture(Pnt3(1.25)),
            nothing,
            true
        )

        # GEOMETRY
        # blue sphere
        glass_translate = Translate(Pnt3(0,0,0)) 
        glass =  parse_obj(
            "../ref/caustic-glass/caustic_glass.obj",
            glass_translate,
            true,
            false,
            nothing
        )

        for tri in glass
            push!(primitives, Primitive(tri, mat_glass, nothing))
        end

        # floor
        floor_transform = Translate(Pnt3(0,0,0))
        floor = Rectangle(
            Pnt2(-15, -15), 
            Pnt2(15, 15), 
            1.456639051,
            2, 
            ShapeCore(floor_transform, Inv(floor_transform), false, false),
            false,
            nothing
        )
        for tri in floor
            push!(primitives, Primitive(tri, mat_gray, nothing))
        end

        # spot light
        spot_light = SpotLight(
            LookAt(Pnt3(0,5,9), Pnt3(-5, 2.75, 0), Vec3(0,-1,0)), 
            spectrum_from_float(1390.8113403320, 1180.6366500854, 1050.3887557983 ), 
            30.0, 
            5.0
        )
        push!(lights, spot_light)
      
        # instantiate accelerator
        print("\nThere are " * num2str(length(primitives)) * " objects in the scene, building BVH\n")
        @time bvh = BVH(primitives)
        print("Done building BVH\n")

        # Instantiate a Filter
        filter = BoxFilter(Pnt2(.25, .25))

        # Instantiate a Film
        film = Film(
            Pnt2(parsed_args["image-dim"], parsed_args["image-dim"]),
            Bounds2(Pnt2(parsed_args["crop-window"][1], parsed_args["crop-window"][2]), Pnt2(parsed_args["crop-window"][3], parsed_args["crop-window"][4])),
            filter,
            1.0,
            1.0,
            parsed_args["file-name"]
        )

        # Instantiate a Camera
        look_from = Pnt3(-5.5, 7, -5.5)
        look_at = Pnt3(-4.75, 2.25, 0)
        up = Vec3(0, 1, 0)
        screen = Bounds2(Pnt2(-1, -1), Pnt2(1, 1))
        C = PerspectiveCamera(LookAt(look_from, look_at, up), screen, 0.0, 1.0, 0.0, 1e6, 30.0, film)

        # Instantiate a Sampler
        S = StratifiedSampler(parsed_args["samples-per-pixel"], parsed_args["jitter"])
        print("Using " * num2str(S.samples_per_pixel) * " samples per pixel\n")
        
        # Instantiate Scene
        print("There are " * num2str(length(lights)) * " lights in the scene\n")
        scene = Scene(lights, bvh)
        
        # Instantiate an Integrator
        I = BDPTIntegrator(C, S, parsed_args["max-depth"])

        return I, scene
    elseif parsed_args["scene-number"] == 3
        primitives = Primitive[]
        primitives2 = Primitive[]
        lights = Light[]
        lights2 = Light[]

        # MATERIALS
        mat_white = Matte(
            ConstantTexture(spectrum_from_float(1.0, 1.0, 1.0)),
            ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
            nothing
        )

        # instantiate objects
        identity_shape_core = ShapeCore(
            Translate(Pnt3(0)),
            Translate(Pnt3(0)),
            false,
            false
        )
        floor = Rectangle(
            Pnt2(-250, -250), 
            Pnt2(750, 750), 
            0.0,
            2, 
            identity_shape_core,
            false,
            nothing
        )
        for tri in floor
            push!(primitives, Primitive(tri, mat_white, nothing))
        end

        dragon_translate = Translate(Pnt3(340, 80, 275)) * RotateY(140.0) * RotateZ(-135.0) * Scale(Vec3(1.5, 1.5, 1.5))
        dragon =  parse_obj(
            "../ref/dragon1.obj",
            dragon_translate,
            false,
            false,
            nothing
        )

        for tri in dragon
            push!(primitives, Primitive(tri, mat_white, nothing))
        end

        # instantiate accelerator
        print("\nThere are " * num2str(length(primitives)) * " objects in the scene, building BVH\n")
        @time bvh = BVH(primitives)
        print("Done building BVH\n")

        # Instantiate a Filter
        filter = BoxFilter(Pnt2(.1, .1))

        # Instantiate a Film
        film = Film(
            Pnt2(parsed_args["image-dim"], parsed_args["image-dim"]),
            Bounds2(Pnt2(parsed_args["crop-window"][1], parsed_args["crop-window"][2]), Pnt2(parsed_args["crop-window"][3], parsed_args["crop-window"][4])),
            filter,
            1.0,
            1.0,
            parsed_args["file-name"]
        )

        # Instantiate a Camera
        look_from = Pnt3(278, 278, -300)
        look_at = Pnt3(278, 150, 0)
        up = Vec3(0, 1, 0)
        screen = Bounds2(Pnt2(-1, -1), Pnt2(1, 1))
        C = PerspectiveCamera(LookAt(look_from, look_at, up), screen, 0.0, 1.0, 0.0, 1e6, 40.0, film)

        # Instantiate a Sampler
        S = StratifiedSampler(parsed_args["samples-per-pixel"], parsed_args["jitter"])
        print("Using " * num2str(S.samples_per_pixel) * " samples per pixel\n")
        
        # Instantiate Scene
        print("There are " * num2str(length(lights)) * " lights in the scene\n")
        scene = Scene(lights, bvh)
        
        # Instantiate an Integrator
        I = AOIntegrator(C, S, true)

        return I, scene
    elseif parsed_args["scene-number"] == 4
        primitives = Primitive[]
        primitives2 = Primitive[]
        lights = Light[]
        lights2 = Light[]

        # MATERIALS
        mat_gray = Matte(
            ConstantTexture(spectrum_from_float(.75, .75, .75)),
            ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
            nothing
        )
        mat_white = Matte(
            ConstantTexture(spectrum_from_float(1.0, 1.0, 1.0)),
            ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
            nothing
        )
        mat_red = Matte(
            ConstantTexture(spectrum_from_float(1.0, 0.0, 0.0)),
            ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
            nothing
        )
        mat_blue = Matte(
            ConstantTexture(spectrum_from_float(0.0, 0.0, 1.0)),
            ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
            nothing
        )
        mat_green = Matte(
            ConstantTexture(spectrum_from_float(0.0, 1.0, 0.0)),
            ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
            nothing
        )
        mat_ball = Substrate(
            ConstantTexture(spectrum_from_float(0.0, .5, .6)), # kd
            ConstantTexture(spectrum_from_float(.15, .15, .15)), # ks
            ConstantTexture(spectrum_from_float(.003, .003, .003)), # u
            ConstantTexture(spectrum_from_float(.003, .003, .003)), # v
            true, # remap
            nothing,
        )
        mat_metal = Metal()

        # instantiate objects
        identity_shape_core = ShapeCore(
            Translate(Pnt3(0)),
            Translate(Pnt3(0)),
            false,
            false
        )
        floor = Rectangle(
            Pnt2(0, 0), 
            Pnt2(555, 555), 
            0.0,
            2, 
            identity_shape_core,
            false,
            nothing
        )
        for tri in floor
            push!(primitives, Primitive(tri, mat_gray, nothing))
        end
        ceiling = Rectangle(
            Pnt2(0, 0), 
            Pnt2(555, 555), 
            555.0,
            2, 
            ShapeCore(Translate(Pnt3(0)),Translate(Pnt3(0)),true,false),
            false,
            nothing
        )
        for tri in ceiling
            push!(primitives, Primitive(tri, mat_gray, nothing))
        end
        backwall = Rectangle(
            Pnt2(0, 0), 
            Pnt2(555, 555), 
            555.0,
            3, 
            identity_shape_core,
            true,
            nothing
        )
        for tri in backwall
            push!(primitives, Primitive(tri, mat_gray, nothing))
        end
        leftwall = Rectangle(
            Pnt2(0, 0), 
            Pnt2(555, 555), 
            0.0,
            1, 
            identity_shape_core,
            true,
            nothing
        )
        for tri in leftwall
            push!(primitives, Primitive(tri, mat_red, nothing))
        end
        rightwall = Rectangle(
            Pnt2(0, 0), 
            Pnt2(555, 555), 
            555.0,
            1, 
            identity_shape_core,
            false,
            nothing
        )
        for tri in rightwall
            push!(primitives, Primitive(tri, mat_green, nothing))
        end

        ceiling_light = Rectangle(
            Pnt2(213, 213), 
            Pnt2(343, 343), 
            554.0,
            2, 
            identity_shape_core,
            true,
            nothing
        )
        for tri in reverse(ceiling_light)
            alight = DiffuseAreaLight(
                spectrum_from_float(20.0, 20.0, 20.0, Illuminant),
                tri,
                false # NOT two sided
            )
            push!(lights,alight)
            push!(primitives, Primitive(tri, mat_white, alight))
        end
        #######################################
        ###### FOR VALIDATION USE SPHERE ######
        #######################################
        # My triangle sample is using pbrtv4 not v3 so use a spehere to make validating against v3 easier
        # s = Sphere(
        #     ShapeCore(
        #         Translate(Pnt3(0, 525, 0)),
        #         Inv(Translate(Pnt3(0, 525, 0))),
        #         false,
        #         false
        #     ),
        #     25.0
        # )
        # alight = DiffuseAreaLight(
        #     spectrum_from_float(200.0, 200.0, 200.0, Illuminant),
        #     s,
        #     false
        # )
        # push!(lights, alight)
        # push!(primitives, Primitive(s, mat_white, alight))

        box_1_transform = Translate(Pnt3(265, 0, 295)) * RotateY(25.0)
        box_1 = Box(
            Pnt3(0,0,0), 
            Pnt3(165,  330, 165), 
            ShapeCore(box_1_transform, Inv(box_1_transform), false, false),
            nothing
        )
        for tri in box_1
            push!(primitives, Primitive(tri, mat_gray, nothing))
        end

        box_2_transform = Translate(Pnt3(130, 0, 65)) * RotateY(-18.0)
        box_2 = Box(
            Pnt3(0,0,0), 
            Pnt3(165,  165, 165), 
            ShapeCore(box_2_transform, Inv(box_2_transform), false, false),
            nothing
        )
        for tri in box_2
            push!(primitives, Primitive(tri, mat_gray, nothing))
        end

        sphere_transform = Translate(Pnt3(130,250,65))
        sphere = Sphere(
            ShapeCore(
                sphere_transform,
                Inv(sphere_transform),
                false,
                false
            ),
            100.0
        )
        smoke_mi = MediumInterface(
            HomogenousMedium(spectrum_from_float(0.001), spectrum_from_float(0.015)),
            nothing
        )
        push!(primitives, Primitive(sphere, nothing, nothing, smoke_mi))

        # instantiate accelerator
        print("\nThere are " * num2str(length(primitives)) * " objects in the scene, building BVH\n")
        @time bvh = BVH(primitives)
        print("Done building BVH\n")

        # Instantiate a Filter
        filter = BoxFilter(Pnt2(.1, .1))

        # Instantiate a Film
        film = Film(
            Pnt2(parsed_args["image-dim"], parsed_args["image-dim"]),
            Bounds2(Pnt2(parsed_args["crop-window"][1], parsed_args["crop-window"][2]), Pnt2(parsed_args["crop-window"][3], parsed_args["crop-window"][4])),
            filter,
            1.0,
            1.0,
            parsed_args["file-name"]
        )

        # Instantiate a Camera
        look_from = Pnt3(278, 278, -800)
        look_at = Pnt3(278, 278, 0)
        up = Vec3(0, 1, 0)
        screen = Bounds2(Pnt2(-1, -1), Pnt2(1, 1))
        C = PerspectiveCamera(LookAt(look_from, look_at, up), screen, 0.0, 1.0, 0.0, 1e6, 40.0, film)

        # Instantiate a Sampler
        S = ZSobolSampler(parsed_args["samples-per-pixel"], film.full_resolution, Int8(2))
        print("Using " * num2str(S.samples_per_pixel) * " samples per pixel\n")
        
        # Instantiate Scene
        print("There are " * num2str(length(lights)) * " lights in the scene\n")
        scene = Scene(lights, bvh)
        
        # Instantiate an Integrator
        I = BDPTIntegrator(C, S, parsed_args["max-depth"])

        return I, scene
    elseif parsed_args["scene-number"] == 5
        primitives = Primitive[]
        lights = Light[]

        # MATERIALS
        mat_gray = Matte(
            ConstantTexture(spectrum_from_float(.4, .4, .4)),
            ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
            nothing
        )
        mat_blue = Matte(
            ConstantTexture(spectrum_from_float(0.05, 0.05, .9)),
            ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
            nothing
        )
        mat_white = Matte(
            ConstantTexture(spectrum_from_float(1.0, 1.0, 1.0)),
            ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
            nothing
        )
        mat_metal = Metal()

        # instantiate objects
        identity_shape_core = ShapeCore(
            Translate(Pnt3(0)),
            Translate(Pnt3(0)),
            false,
            false
        )
        floor = Rectangle(
            Pnt2(-25, -25), 
            Pnt2(25, 25), 
            0.0,
            2, 
            identity_shape_core,
            false,
            nothing
        )
        for tri in floor
            push!(primitives, Primitive(tri, mat_gray, nothing))
        end
        light_location_scale = 1.8
        light_intensity_scale = 1.3
        spot_light1 = SpotLight(
            LookAt(light_location_scale * Pnt3(8, 8, 8), Pnt3(0, 0, 0), Vec3(0,-1,0)), 
            light_intensity_scale * spectrum_from_float(245.8113403320, 258.6366500854, 200.3887557983 ), 
            30.0, 
            5.0
        )
        push!(lights, spot_light1)

        spot_light2 = SpotLight(
            LookAt(light_location_scale * Pnt3(-10, 5, -10), Pnt3(0, 0, 0), Vec3(0,-1,0)), 
            light_intensity_scale * spectrum_from_float(200.8113403320, 200.0, 250.3887557983 ), 
            30.0, 
            5.0
        )
        push!(lights, spot_light2)

        spot_light3 = SpotLight(
            LookAt(light_location_scale * Pnt3(-15, 7, 8), Pnt3(0, 0, 0), Vec3(0,-1,0)), 
            light_intensity_scale * spectrum_from_float(350.8113403320, 167.6366500854, 297.3887557983 ), 
            30.0, 
            5.0
        )
        push!(lights, spot_light3)

        spot_light4 = SpotLight(
            LookAt(light_location_scale * Pnt3(5, 20, -5), Pnt3(0, 0, 0), Vec3(0,-1,0)), 
            light_intensity_scale * spectrum_from_float(260.8113403320, 250.6366500854, 290.3887557983 ), 
            30.0, 
            5.0
        )
        push!(lights, spot_light4)

        softy_t = Translate(Pnt3(0, 0, 0))
        softy_core = ShapeCore(
            softy_t,
            Inv(softy_t),
            false,
            false
        )
        # can use a BVH of BasicSpheres
        # meta_balls = MetaBallsBVH(
        #     softy_core, 
        #     BVH([
        #         BasicSphere(Pnt3(asdf/2,  3.0, 0.0), 3.0),
        #         BasicSphere(Pnt3(-asdf/2, 3.0, 0.0), 3.0),
        #         BasicSphere(Pnt3(0.0,     3.0, sqrt(asdf^2 - (asdf/2)^2)), 3.0)
        #     ])
        # )

        N = 4
        R = 13
        points = Pnt3[]
        for x in 1:N
            for z in 1:N
                px = (x - 0.5) / N * R - R / 2.0
                pz = (z - 0.5) / N * R - R / 2.0
                if (x == N-N/2) || (z == N-N/2)
                    adj = 4.0
                else
                    adj =  (1.0 / ((N-x-N/2)^2)) + (1.0 / ((N-z-N/2)^2))
                end
                p = Pnt3(px, 3.0 + adj, pz)
                print("Meta Ball: $(p)\n")
                push!(points, p)
            end
        end
        meta_balls = MetaBalls(
            softy_core, 
            points
        )
        push!(primitives, Primitive(meta_balls, mat_blue, nothing))

        # instantiate accelerator
        print("\nThere are " * num2str(length(primitives)) * " objects in the scene, building BVH\n")
        @time bvh = BVH(primitives)
        print("Done building BVH\n")

        # l_2_w = Translate(Pnt3(0,0,0))
        # light = InfiniteLight(
        #     world_bounds(bvh), 
        #     l_2_w, 
        #     Spectrum(2.0, 2.0, 2.0), 
        #     "/Users/johnmyslinski/Documents/pbrt-v3-scenes/cloud/textures/skylight-morn.exr"
        # )
        # push!(lights, light)

        # Instantiate a Filter
        filter = BoxFilter(Pnt2(.5, .5))

        # Instantiate a Film
        film = Film(
            Pnt2(parsed_args["image-dim"], parsed_args["image-dim"]),
            Bounds2(Pnt2(parsed_args["crop-window"][1], parsed_args["crop-window"][2]), Pnt2(parsed_args["crop-window"][3], parsed_args["crop-window"][4])),
            filter,
            1.0,
            1.0,
            parsed_args["file-name"]
        )

        # Instantiate a Camera
        look_from = Pnt3(20, 30, 10)
        look_at = Pnt3(0, 0, 0)
        up = Vec3(0, 1, 0)
        screen = Bounds2(Pnt2(-1, -1), Pnt2(1, 1))
        C = PerspectiveCamera(LookAt(look_from, look_at, up), screen, 0.0, 1.0, 0.0, 1e6, 55.0, film)

        # Instantiate a Sampler
        S = ZSobolSampler(parsed_args["samples-per-pixel"], Pnt2(parsed_args["image-dim"], parsed_args["image-dim"]), Int8(2))
        print("Using " * num2str(S.samples_per_pixel) * " samples per pixel\n")
        
        # Instantiate Scene
        print("There are " * num2str(length(lights)) * " lights in the scene\n")
        scene = Scene(lights, bvh)
        
        # Instantiate an Integrator
        I = BDPTIntegrator(C, S, parsed_args["max-depth"])
        return I, scene
    
    elseif parsed_args["scene-number"] == 6
        primitives = Primitive[]
        lights = Light[]

        # MATERIALS
        mat_gray = Matte(
            ConstantTexture(spectrum_from_float(.4, .4, .4)),
            ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
            nothing
        )
        mat_blue = Matte(
            ConstantTexture(spectrum_from_float(0.05, 0.05, .9)),
            ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
            nothing
        )
        mat_red = Matte(
            ConstantTexture(spectrum_from_float(0.88, 0.05, .07)),
            ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
            nothing
        )
        mat_white = Matte(
            ConstantTexture(spectrum_from_float(1.0, 1.0, 1.0)),
            ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
            nothing
        )
        mat_metal = Metal()

        # instantiate objects
        identity_shape_core = ShapeCore()

        spot_light1 = SpotLight(
            LookAt(Pnt3(8, 8, 8), Pnt3(0, 0, 0), Vec3(0,-1,0)), 
            spectrum_from_float(245.8113403320, 258.6366500854, 200.3887557983 ), 
            30.0, 
            5.0
        )
        push!(lights, spot_light1)

        spot_light2 = SpotLight(
            LookAt(Pnt3(-10, 5, -10), Pnt3(0, 0, 0), Vec3(0,-1,0)), 
            spectrum_from_float(200.8113403320, 200.0, 250.3887557983 ), 
            30.0, 
            5.0
        )
        push!(lights, spot_light2)

        spot_light3 = SpotLight(
            LookAt(Pnt3(-15, 7, 8), Pnt3(0, 0, 0), Vec3(0,-1,0)), 
            spectrum_from_float(350.8113403320, 167.6366500854, 297.3887557983 ), 
            30.0, 
            5.0
        )
        push!(lights, spot_light3)

        spot_light4 = SpotLight(
            LookAt(Pnt3(5, 20, -5), Pnt3(0, 0, 0), Vec3(0,-1,0)), 
            spectrum_from_float(260.8113403320, 250.6366500854, 290.3887557983 ), 
            30.0, 
            5.0
        )
        push!(lights, spot_light4)

        floor_t = Translate(Pnt3(0, -3.0, 0))
        floor_sc = ShapeCore(
            floor_t,
            Inv(floor_t),
            false,
            false
        )
        floor = Rectangle(
            Pnt2(-25, -25), 
            Pnt2(25, 25), 
            0.0,
            2, 
            floor_sc,
            # identity_shape_core,
            false,
            nothing
        )
        for tri in floor
            push!(primitives, Primitive(tri, mat_gray, nothing))
        end

        for (col, offset, rot) in [(mat_red, 2.5, RotateX(0.0)), (mat_blue, -2.5, RotateX(45.0))]
            goursat_t = Translate(Pnt3(0 + offset, 0, 0)) * rot
            goursat_sc = ShapeCore(
                goursat_t,
                Inv(goursat_t),
                false,
                false
            )
            goursat = GoursatSurface(
                goursat_sc,
                0.0,
                -2.0,
                1.5
            )
            push!(primitives, Primitive(goursat, col, nothing))
        end

        # instantiate accelerator
        print("\nThere are " * num2str(length(primitives)) * " objects in the scene, building BVH\n")
        @time bvh = BVH(primitives)
        print("Done building BVH\n")

        # Instantiate a Filter
        filter = BoxFilter(Pnt2(.5, .5))

        # Instantiate a Film
        film = Film(
            Pnt2(parsed_args["image-dim"], parsed_args["image-dim"]),
            Bounds2(Pnt2(parsed_args["crop-window"][1], parsed_args["crop-window"][2]), Pnt2(parsed_args["crop-window"][3], parsed_args["crop-window"][4])),
            filter,
            1.0,
            1.0,
            parsed_args["file-name"]
        )

        # Instantiate a Camera
        look_from = Pnt3(10, 15, 5)
        look_at = Pnt3(0, 0, 0)
        up = Vec3(0, 1, 0)
        screen = Bounds2(Pnt2(-1, -1), Pnt2(1, 1))
        C = PerspectiveCamera(LookAt(look_from, look_at, up), screen, 0.0, 1.0, 0.0, 1e6, 30.0, film)

        # Instantiate a Sampler
        S = StratifiedSampler(parsed_args["samples-per-pixel"], parsed_args["jitter"])
        print("Using " * num2str(S.samples_per_pixel) * " samples per pixel\n")
        
        # Instantiate Scene
        print("There are " * num2str(length(lights)) * " lights in the scene\n")
        scene = Scene(lights, bvh)
        
        # Instantiate an Integrator
        I = BDPTIntegrator(C, S, parsed_args["max-depth"])
        return I, scene
    elseif parsed_args["scene-number"] == 7
        primitives = Primitive[]
        lights = Light[]

        # MATERIALS
        mat_gray = Matte(
            ConstantTexture(spectrum_from_float(.4, .4, .4)),
            ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
            nothing
        )
        mat_white = Matte(
            ConstantTexture(spectrum_from_float(1.0, 1.0, 1.0)),
            ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
            nothing
        )
        mat_julia_green = Matte(
            ConstantTexture(spectrum_from_float(0.22, 0.596, .149)),
            ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
            nothing
        )
        mat_julia_purple = Matte(
            ConstantTexture(spectrum_from_float(0.584, .345, .698)),
            ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
            nothing
        )
        mat_julia_red = Matte(
            ConstantTexture(spectrum_from_float(.235, .2, .796)),
            ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
            nothing
        )
        #######################
        # instantiate objects #
        #######################
        # walls
        identity_shape_core = ShapeCore()
        floor = Rectangle(
            Pnt2(-250, -250), 
            Pnt2(250, 250), 
            0.0,
            2, 
            identity_shape_core,
            false,
            nothing
        )
        for tri in floor
            push!(primitives, Primitive(tri, mat_gray, nothing))
        end

        back_wall = Rectangle(
            Pnt2(0, -100), 
            Pnt2(75, 100), 
            -100.0,
            1, 
            identity_shape_core,
            false,
            nothing
        )
        for tri in back_wall
            push!(primitives, Primitive(tri, mat_gray, nothing))
        end

        side_wall = Rectangle(
            Pnt2(-100, 0), 
            Pnt2(100, 75), 
            -45.0,
            3, 
            identity_shape_core,
            false,
            nothing
        )
        for tri in side_wall
            push!(primitives, Primitive(tri, mat_gray, nothing))
        end

        for i in 0:6
            start = -100
            width = 20
            space = 10
            rafter = Box(
                Pnt3(start + i * (width + space),         75,  -250),
                Pnt3(start + i * (width + space) + width, 100,  250),
                identity_shape_core,
                nothing
            )
            for tri in rafter
                push!(primitives, Primitive(tri, mat_white, nothing))
            end

            light_tris = Rectangle(
                Pnt2(start +     i   * (width + space) + width + 1.0, -250), 
                Pnt2(start + (i + 1) * (width + space)         - 1.0, 250), 
                95.0,
                2, 
                identity_shape_core,
                true,
                nothing
            )
            for tri in light_tris
                alight = DiffuseAreaLight(
                    spectrum_from_float(4.0),
                    tri,
                    false
                )
                push!(lights, alight)
                push!(primitives, Primitive(tri, mat_white, alight))
            end
            # print(
            #     "       Box $(i+1)
            #             - start: $(start + i * (width + space))
            #             - end: $(start + i * (width + space) + width)
            #             Light $(i+1)
            #             - start: $(start +     i * (width + space) + width + 1.0)
            #             - end: $(start + (i + 1) * (width + space)         - 1.0)\n\n\n
            #     "
            # )
        end

        # asdf = 20.0
        # sphere1_t = Translate(Pnt3(0, 20, asdf/2.0))
        # sphere1_sc = ShapeCore(sphere1_t, Inv(sphere1_t), false, false)
        # sphere1 = Sphere(sphere1_sc, asdf/2.0)
        # push!(primitives, Primitive(sphere1, mat_julia_red, nothing))

        # sphere2_t = Translate(Pnt3(0, 20, -asdf/2.0))
        # sphere2_sc = ShapeCore(sphere2_t, Inv(sphere2_t), false, false)
        # sphere2 = Sphere(sphere2_sc, asdf/2.0)
        # push!(primitives, Primitive(sphere2, mat_julia_purple, nothing))

        # sphere3_t = Translate(Pnt3(0, 20 + sqrt(asdf^2 - (asdf/2.0)^2), 0))
        # sphere3_sc = ShapeCore(sphere3_t, Inv(sphere3_t), false, false)
        # sphere3 = Sphere(sphere3_sc, asdf/2.0)
        # push!(primitives, Primitive(sphere3, mat_julia_green, nothing))

        asdf = 20.0
        teapot_scale = 0.175
        teapot_y_shift = 20
        rotate_y = 45.0
        teapot_t1 = Translate(Pnt3(0, teapot_y_shift, asdf/2.0)) * RotateY(rotate_y) * Scale(Vec3(teapot_scale, teapot_scale, teapot_scale))
        teapot1 = parse_obj("../ref/teapot.obj", teapot_t1, false, false, nothing) 
        for tri in teapot1
            push!(primitives, Primitive(tri, mat_julia_red, nothing))
        end

        teapot_t2 = Translate(Pnt3(0, teapot_y_shift, -asdf/2.0)) * RotateY(rotate_y) * Scale(Vec3(teapot_scale, teapot_scale, teapot_scale))
        teapot2 = parse_obj("../ref/teapot.obj", teapot_t2, false, false, nothing) 
        for tri in teapot2
            push!(primitives, Primitive(tri, mat_julia_purple, nothing))
        end

        teapot_t3 = Translate(Pnt3(0, teapot_y_shift + sqrt(asdf^2 - (asdf/2.0)^2), 0)) * RotateY(rotate_y) * Scale(Vec3(teapot_scale, teapot_scale, teapot_scale))
        teapot3 = parse_obj("../ref/teapot.obj", teapot_t3, false, false, nothing) 
        for tri in teapot3
            push!(primitives, Primitive(tri, mat_julia_green, nothing))
        end

        # instantiate lights
        light_t = Translate(Pnt3(0, 100, 0))
        light_sc = ShapeCore(light_t, Inv(light_t), false, false)
        light_tris = Rectangle(
            Pnt2(-50, -50), 
            Pnt2(50, 50), 
            0.0,
            2, 
            light_sc,
            true,
            nothing
        )
        for tri in light_tris
            alight = DiffuseAreaLight(
                spectrum_from_float(4.0),
                tri,
                false
            )
            push!(lights, alight)
            push!(primitives, Primitive(tri, mat_white, alight))
        end

        # instantiate accelerator
        print("\nThere are " * num2str(length(primitives)) * " objects in the scene, building BVH\n")
        @time bvh = BVH(primitives)
        print("Done building BVH\n")

        # Instantiate a Filter
        filter = BoxFilter(Pnt2(.5, .5))

        # Instantiate a Film
        film = Film(
            Pnt2(parsed_args["image-dim"], parsed_args["image-dim"]),
            Bounds2(Pnt2(parsed_args["crop-window"][1], parsed_args["crop-window"][2]), Pnt2(parsed_args["crop-window"][3], parsed_args["crop-window"][4])),
            filter,
            1.0,
            1.0,
            parsed_args["file-name"]
        )

        # Instantiate a Camera
        look_from = Pnt3(85, 35, 35)
        look_at = Pnt3(0, teapot_y_shift + sqrt(asdf^2 - (asdf/2.0)^2) / 2.0, 0)
        up = Vec3(0, 1, 0)
        screen = Bounds2(Pnt2(-1, -1), Pnt2(1, 1))
        C = PerspectiveCamera(LookAt(look_from, look_at, up), screen, 0.0, 1.0, 0.0, 1e6, 55.0, film)

        # Instantiate a Sampler
        S = StratifiedSampler(parsed_args["samples-per-pixel"], parsed_args["jitter"])
        print("Using " * num2str(S.samples_per_pixel) * " samples per pixel\n")
        
        # Instantiate Scene
        print("There are " * num2str(length(lights)) * " lights in the scene\n")
        scene = Scene(lights, bvh)
        
        # Instantiate an Integrator
        I = BDPTIntegrator(C, S, parsed_args["max-depth"])
        return I, scene
    elseif parsed_args["scene-number"] == 8
        primitives = Primitive[]
        lights = Light[]

        # MATERIALS
        mat_gray = Matte(
            ConstantTexture(spectrum_from_float(.4, .4, .4)),
            ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
            nothing
        )
        mat_white = Matte(
            ConstantTexture(spectrum_from_float(1.0, 1.0, 1.0)),
            ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
            nothing
        )
        mat_julia_green = Matte(
            ConstantTexture(spectrum_from_float(0.22, 0.596, .149)),
            ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
            nothing
        )
        mat_julia_purple = Matte(
            ConstantTexture(spectrum_from_float(0.584, .345, .698)),
            ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
            nothing
        )
        mat_julia_red = Matte(
            ConstantTexture(spectrum_from_float(.235, .2, .796)),
            ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
            nothing
        )
        #######################
        # instantiate objects #
        #######################
        # walls
        identity_shape_core = ShapeCore()
        floor = Rectangle(
            Pnt2(-250, -250), 
            Pnt2(250, 250), 
            0.0,
            2, 
            identity_shape_core,
            false,
            nothing
        )
        for tri in floor
            push!(primitives, Primitive(tri, mat_gray, nothing))
        end

        back_wall = Rectangle(
            Pnt2(0, -100), 
            Pnt2(75, 100), 
            -100.0,
            1, 
            identity_shape_core,
            false,
            nothing
        )
        for tri in back_wall
            push!(primitives, Primitive(tri, mat_gray, nothing))
        end

        side_wall = Rectangle(
            Pnt2(-100, 0), 
            Pnt2(100, 75), 
            -45.0,
            3, 
            identity_shape_core,
            false,
            nothing
        )
        for tri in side_wall
            push!(primitives, Primitive(tri, mat_gray, nothing))
        end

        for i in 0:6
            start = -100
            width = 20
            space = 10
            rafter = Box(
                Pnt3(start + i * (width + space),         75,  -250),
                Pnt3(start + i * (width + space) + width, 100,  250),
                identity_shape_core,
                nothing
            )
            for tri in rafter
                push!(primitives, Primitive(tri, mat_white, nothing))
            end

            light_tris = Rectangle(
                Pnt2(start +     i   * (width + space) + width + 1.0, -250), 
                Pnt2(start + (i + 1) * (width + space)         - 1.0, 250), 
                95.0,
                2, 
                identity_shape_core,
                true,
                nothing
            )
            for tri in light_tris
                alight = DiffuseAreaLight(
                    spectrum_from_float(4.0),
                    tri,
                    false
                )
                push!(lights, alight)
                push!(primitives, Primitive(tri, mat_white, alight))
            end
        end

        # constants
        asdf = 20.0
        teapot_y_shift = 20

        # # test cylindar
        # cylindar_t = LookAt(Pnt3(0, 0, 0), Pnt3(0, 12, 30), Vec3(0, 1, 0)) * RotateX(-90.0)
        # cyl = Cylindar(cylindar_t, 5.0, 0.0, 20.0)
        # push!(primitives, Primitive(cyl, mat_julia_green, nothing))

        d1 = Dict("X" => "F+[[X]-X]-F[-FX]+X", "F" => "FF")
        lsystem_shapes = LSystem(d1, "X", 3)
        for (i, cyl) in enumerate(lsystem_shapes)
            if i % 2 == 0                
                push!(primitives, Primitive(cyl, mat_julia_red, nothing))
            else
                push!(primitives, Primitive(cyl, mat_julia_green, nothing))
            end
        end

        # instantiate accelerator
        print("\nThere are " * num2str(length(primitives)) * " objects in the scene, building BVH\n")
        @time bvh = BVH(primitives)
        print("Done building BVH\n")

        # Instantiate a Filter
        filter = BoxFilter(Pnt2(.5, .5))

        # Instantiate a Film
        film = Film(
            Pnt2(parsed_args["image-dim"], parsed_args["image-dim"]),
            Bounds2(Pnt2(parsed_args["crop-window"][1], parsed_args["crop-window"][2]), Pnt2(parsed_args["crop-window"][3], parsed_args["crop-window"][4])),
            filter,
            1.0,
            1.0,
            parsed_args["file-name"]
        )

        # Instantiate a Camera
        look_from = Pnt3(85, 35, 35)
        look_at = Pnt3(0, teapot_y_shift + sqrt(asdf^2 - (asdf/2.0)^2) / 2.0, 0)
        up = Vec3(0, 1, 0)
        screen = Bounds2(Pnt2(-1, -1), Pnt2(1, 1))
        C = PerspectiveCamera(LookAt(look_from, look_at, up), screen, 0.0, 1.0, 0.0, 1e6, 55.0, film)

        # Instantiate a Sampler
        S = StratifiedSampler(parsed_args["samples-per-pixel"], parsed_args["jitter"])
        print("Using " * num2str(S.samples_per_pixel) * " samples per pixel\n")
        
        # Instantiate Scene
        print("There are " * num2str(length(lights)) * " lights in the scene\n")
        scene = Scene(lights, bvh)
        
        # Instantiate an Integrator
        I = BDPTIntegrator(C, S, parsed_args["max-depth"])
        return I, scene
    
    elseif parsed_args["scene-number"] == 9
        primitives = Primitive[]
        lights = Light[]

        # materials
        mat_white = Matte(
            ConstantTexture(spectrum_from_float(1.0, 1.0, 1.0)),
            ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
            nothing
        )
        mat_inner = Matte(
            ConstantTexture(spectrum_from_float(0.4, 0.4, 0.7)),
            ConstantTexture(spectrum_from_float(20.0, 20.0, 20.0)),
            nothing
        )

        ##############
        ### a mesh ###
        ##############

        mesh012_translate = Translate(Pnt3(0,0,0)) 
        mesh0 =  parse_obj(
            "../ref/lte-orb/mesh-0.obj",
            mesh012_translate,
            true,
            false,
            nothing
        )
        for tri in mesh0
            push!(primitives, Primitive(tri, mat_inner, nothing))
        end
        mesh1 =  parse_obj(
            "../ref/lte-orb/mesh-1.obj",
            mesh012_translate,
            true,
            false,
            nothing
        )
        for tri in mesh1
            push!(primitives, Primitive(tri, mat_inner, nothing))
        end
        mesh2 =  parse_obj(
            "../ref/lte-orb/mesh-2.obj",
            mesh012_translate,
            true,
            false,
            nothing
        )
        for tri in mesh2
            push!(primitives, Primitive(tri, mat_inner, nothing))
        end



        # instantiate accelerator
        print("\nThere are " * num2str(length(primitives)) * " objects in the scene, building BVH\n")
        @time bvh = BVH(primitives)
        print("Done building BVH\n")

        # instantiate the infinite light
        l_2_w = Translate(Pnt3(0,0,0))
        light = InfiniteLight(world_bounds(bvh), l_2_w, Spectrum(3.0, 3.0, 3.0), "/Users/johnmyslinski/Documents/PBRJ/scratch/mipmap/hello.exr")
        push!(lights, light)

        # Instantiate a Filter
        filter = BoxFilter(Pnt2(.5, .5))

        # Instantiate a Film
        film = Film(
            Pnt2(parsed_args["image-dim"], parsed_args["image-dim"]),
            Bounds2(Pnt2(parsed_args["crop-window"][1], parsed_args["crop-window"][2]), Pnt2(parsed_args["crop-window"][3], parsed_args["crop-window"][4])),
            filter,
            1.0,
            1.0,
            parsed_args["file-name"]
        )

        # Instantiate a Camera
        look_from = Pnt3(-.3, .5, -.5)
        look_at = Pnt3(0, 0.0, 0)
        up = Vec3(0, 1, 0)
        screen = Bounds2(Pnt2(-1, -1), Pnt2(1, 1))
        C = PerspectiveCamera(LookAt(look_from, look_at, up), screen, 0.0, 1.0, 0.0, 1e6, 37.0, film)

        # Instantiate a Sampler
        S = StratifiedSampler(parsed_args["samples-per-pixel"], parsed_args["jitter"])
        print("Using " * num2str(S.samples_per_pixel) * " samples per pixel\n")
        
        # Instantiate Scene
        print("There are " * num2str(length(lights)) * " lights in the scene\n")
        scene = Scene(lights, bvh)
        
        # Instantiate an Integrator
        I = BDPTIntegrator(C, S, parsed_args["max-depth"])
        return I, scene
    elseif parsed_args["scene-number"] == 10
        primitives = Primitive[]
        lights = Light[]

        
        # Bounding sphere cause we hate winding order and such
        box_t = Translate(Pnt3(-1.0, 0.0, -1.2))
        sphere_transform = Translate(Pnt3(.045, 1.045, -.75))
        sphere = Sphere(
            ShapeCore(
                sphere_transform,
                Inv(sphere_transform),
                false,
                false
            ),
            1.4
        )
        smoke_mi = MediumInterface(
            GridDensityMedium(
                spectrum_from_float(10.0),
                spectrum_from_float(90.0),
                0.0,
                Pnt3(0.01, 0.01, 0.01),
                Pnt3(1.99, 1.99, 0.79),
                box_t,
                "/Users/johnmyslinski/Documents/pbrt-v3-scenes/cloud/geometry/density_render.70.pbrt"
            ),
            nothing
        )
        push!(primitives, Primitive(sphere, nothing, nothing, smoke_mi))


        # Orb light cause we hate environment maps (for now)
        # sphere_transform = Translate(Pnt3(0.0720194, -0.52456, 4.60187))
        # sphere = Sphere(
        #     ShapeCore(
        #         sphere_transform,
        #         Inv(sphere_transform),
        #         false,
        #         false
        #     ),
        #     .05
        # )
        # alight = DiffuseAreaLight(
        #     spectrum_from_float(5_000.0),
        #     sphere,
        #     false
        # )
        # light_m = Matte(
        #     ConstantTexture(spectrum_from_float(1.0)),
        #     ConstantTexture(spectrum_from_float(0.0)),
        #     nothing
        # )
        # push!(lights, alight)
        # push!(primitives, Primitive(sphere, light_m, alight))

        # instantiate accelerator
        print("\nThere are " * num2str(length(primitives)) * " objects in the scene, building BVH\n")
        @time bvh = BVH(primitives)
        print("Done building BVH\n")

        # instantiate the infinite light
        l_2_w = Translate(Pnt3(0,0,0))
        light = InfiniteLight(
            world_bounds(bvh), 
            l_2_w, 
            Spectrum(4.0, 4.0, 4.0), 
            "/Users/johnmyslinski/Documents/pbrt-v3-scenes/cloud/textures/skylight-morn.exr"
        )
        push!(lights, light)

        # Instantiate a Filter
        filter = BoxFilter(Pnt2(.5, .5))

        # Instantiate a Film
        film = Film(
            Pnt2(parsed_args["image-dim"], parsed_args["image-dim"]),
            Bounds2(Pnt2(parsed_args["crop-window"][1], parsed_args["crop-window"][2]), Pnt2(parsed_args["crop-window"][3], parsed_args["crop-window"][4])),
            filter,
            1.0,
            1.0,
            parsed_args["file-name"]
        )

        # Instantiate a Camera
        look_from = Pnt3(0.0715308, -4.17677, 5.33558)
        look_at = Pnt3(0.0720194, -3.57456, 4.60187)
        up = Vec3(-0.000323605, 0.833706, 0.552208)
        screen = Bounds2(Pnt2(-1, -1), Pnt2(1, 1))
        C = PerspectiveCamera(LookAt(look_from, look_at, up), screen, 0.0, 1.0, 0.0, 1e6, 15.0, film)

        # Instantiate a Sampler
        S = StratifiedSampler(parsed_args["samples-per-pixel"], parsed_args["jitter"])
        print("Using " * num2str(S.samples_per_pixel) * " samples per pixel\n")
        
        # Instantiate Scene
        print("There are " * num2str(length(lights)) * " lights in the scene\n")
        scene = Scene(lights, bvh)
        
        # Instantiate an Integrator
        I = BDPTIntegrator(C, S, parsed_args["max-depth"])

        return I, scene
    elseif parsed_args["scene-number"] == 11
        primitives = Primitive[]
        lights = Light[]

        # materials
        mat_gray = Matte(
            ConstantTexture(spectrum_from_float(0.6, 0.6, 0.6)),
            ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
            nothing
        )
        mat_blue = Matte(
            ConstantTexture(spectrum_from_float(0.2, 1.0, 0.2)),
            ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
            nothing
        )

        ###############
        ### a thing ###
        ###############

        
        s = Sphere(ShapeCore(Translate(Pnt3(0, 0.025, 0)), Inv(Translate(Pnt3(0, 0.025, 0)))), .075)
        push!(primitives, Primitive(s, mat_blue, nothing))

        floor_transform = Translate(Pnt3(0,0,0))
        floor = Rectangle(
            Pnt2(-10, -10),
            Pnt2(10, 10),
            0.0,
            2, 
            ShapeCore(floor_transform, Inv(floor_transform), false, false),
            false,
            nothing
        )
        for tri in floor
            push!(primitives, Primitive(tri, mat_gray, nothing))
        end

        # instantiate accelerator
        print("\nThere are " * num2str(length(primitives)) * " objects in the scene, building BVH\n")
        @time bvh = BVH(primitives)
        print("Done building BVH\n")

        # instantiate the infinite light
        l_2_w = Translate(Pnt3(0,0,0))
        light = InfiniteLight(
            world_bounds(bvh), 
            l_2_w, 
            Spectrum(3.0, 3.0, 3.0), 
            "/Users/johnmyslinski/Documents/pbrt-v3-scenes/cloud/textures/skylight-morn.exr"
        )
        push!(lights, light)

        # Instantiate a Filter
        filter = BoxFilter(Pnt2(.5, .5))

        # Instantiate a Film
        film = Film(
            Pnt2(parsed_args["image-dim"], parsed_args["image-dim"]),
            Bounds2(Pnt2(parsed_args["crop-window"][1], parsed_args["crop-window"][2]), Pnt2(parsed_args["crop-window"][3], parsed_args["crop-window"][4])),
            filter,
            1.0,
            1.0,
            parsed_args["file-name"]
        )

        # Instantiate a Camera
        look_from = Pnt3(-.3, .5, -.5)
        look_at = Pnt3(0, 0.0, 0)
        up = Vec3(0, 1, 0)
        screen = Bounds2(Pnt2(-1, -1), Pnt2(1, 1))
        C = PerspectiveCamera(LookAt(look_from, look_at, up), screen, 0.0, 1.0, 0.0, 1e6, 37.0, film)

        # Instantiate a Sampler
        S = ZSobolSampler(
            parsed_args["samples-per-pixel"], 
            Pnt2(parsed_args["image-dim"], parsed_args["image-dim"]), 
            Int8(2)
        )
        print("Using " * num2str(S.samples_per_pixel) * " samples per pixel\n")
        
        # Instantiate Scene
        print("There are " * num2str(length(lights)) * " lights in the scene\n")
        scene = Scene(lights, bvh)
        
        # Instantiate an Integrator
        I = BDPTIntegrator(C, S, parsed_args["max-depth"])
        return I, scene
    elseif parsed_args["scene-number"] == 99
        base_t = RayTracing.Translate(RayTracing.Pnt3(0,0,0))
        max_depth = 4
        r = 0.5
        r_vec = Float64[r^(i-1) for i in 1:max_depth]
        spheres = RayTracing.Sphere[]
        recursive_pyramid_build!(
            spheres,
            base_t,
            r_vec,
            1,
            4
        )

        primitives = Primitive[]
        mat_gray = Matte(
            ConstantTexture(spectrum_from_float(0.6, 0.6, 0.6)),
            ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
            nothing
        )
        for sphere in spheres
            push!(primitives, Primitive(sphere, mat_gray, nothing))
        end

        # instantiate accelerator
        print("\nThere are " * num2str(length(primitives)) * " objects in the scene, building BVH\n")
        @time bvh = BVH(primitives)
        print("Done building BVH\n")

        # instantiate the infinite light
        l_2_w = Translate(Pnt3(0,0,0))
        light = InfiniteLight(
            world_bounds(bvh), 
            l_2_w, 
            Spectrum(5.0, 5.0, 5.0), 
            "/Users/johnmyslinski/Documents/pbrt-v3-scenes/cloud/textures/skylight-morn.exr"
        )
        lights = Light[]
        push!(lights, light)

        # Instantiate a Filter
        filter = BoxFilter(Pnt2(.5, .5))

        # Instantiate a Film
        film = Film(
            Pnt2(parsed_args["image-dim"], parsed_args["image-dim"]),
            Bounds2(Pnt2(parsed_args["crop-window"][1], parsed_args["crop-window"][2]), Pnt2(parsed_args["crop-window"][3], parsed_args["crop-window"][4])),
            filter,
            1.0,
            1.0,
            parsed_args["file-name"]
        )

        # Instantiate a Camera
        look_from = Pnt3(-10, 4, -10)
        look_at = centroid(world_bounds(bvh))
        up = Vec3(0, 1, 0)
        screen = Bounds2(Pnt2(-1, -1), Pnt2(1, 1))
        C = PerspectiveCamera(LookAt(look_from, look_at, up), screen, 0.0, 1.0, 0.0, 1e6, 20.0, film)

        # Instantiate a Sampler
        S = ZSobolSampler(
            parsed_args["samples-per-pixel"], 
            Pnt2(parsed_args["image-dim"], parsed_args["image-dim"]), 
            Int8(2)
        )
        print("Using " * num2str(S.samples_per_pixel) * " samples per pixel\n")

        # Instantiate Scene
        print("There are " * num2str(length(lights)) * " lights in the scene\n")
        scene = Scene(lights, bvh)

        # Instantiate an Integrator
        I = BDPTIntegrator(C, S, parsed_args["max-depth"])
        return I, scene
    else
        @assert false
    end
end

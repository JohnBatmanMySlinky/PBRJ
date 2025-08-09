function make_scene16(parsed_args::Dict)::Tuple{AbstractIntegrator, Scene}
    primitives = Primitive[]
    lights = Light[]
    materials = Material[]
    textures = AbstractTexture[]

    ################################
    ####### Materials
    ################################
    mat_gray = Matte(
        "mat_gray",
        ConstantTexture(spectrum_from_float(.9, .9, .795)),
        ConstantTexture(20.0),
        nothing
    )
    push!(materials, mat_gray)

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

    mat_black = Plastic(
        "mat_black",
        ConstantTexture(spectrum_from_float(0.1, 0.1, 0.1)),
        ConstantTexture(spectrum_from_float(0.2, 0.2, 0.2)),
        ConstantTexture(0.1),
        nothing,
        nothing,
        nothing,
        true,
    )
    push!(materials, mat_black)

    mat_black_shiny = Mirror(
        "mat_black_shiny",
        ConstantTexture(spectrum_from_float(0.95, 0.95, 0.95))
    )
    push!(materials, mat_black_shiny)

    mat_concrete = Substrate(
        "mat_concrete",
        ImageTexture(
            UVMapping2D(), 
            jmfp("/Users/johnmyslinski/Documents/PBRJ/ref/Substance_Graph_BaseColor.jpg"),
            # "../ref/Marble_Gray_001_COLOR.jpg",
            false
        ), # kd
        ConstantTexture(spectrum_from_float(.15, .15, .15)), # ks
        ConstantTexture(0.00002), # u
        ConstantTexture(0.00002), # v
        nothing, # bump
        true # remap
        # ImageTexture(UVMapping2D(), "../ref/Substance_Graph_Height.jpg"), # bump
    )
    push!(materials, mat_concrete)

    mat_metal_door = Metal(
        "mat_metal_door",
        ConstantTexture(spectrum_from_float(0.155, 0.116, 0.138)),
        ConstantTexture(spectrum_from_float(0.482, 0.312, 0.214)),
        nothing,
        ConstantTexture(.01),
        ConstantTexture(.2),
        nothing,
        true
    )
    push!(materials, mat_metal_door)

    mat_silver_panel = Metal(
        "mat_silver_panel",
        ConstantTexture(spectrum_from_float(0.755, 0.716, 0.838)),
        ConstantTexture(spectrum_from_float(0.482, 0.312, 0.214)),
        ConstantTexture(.01),
        nothing,
        nothing,
        nothing,
        true
    )
    push!(materials, mat_silver_panel)

    mat_wood_walls = Plastic(
        "mat_wood_walls",
        ImageTexture(
            UVMapping2D(),
            jmfp("/home/jmyslinski/random_stuff/PBRJ/ref/elevator_wood_1_albedo.png"),
            false
        ),
        ImageTexture(
            UVMapping2D(),
            jmfp("/home/jmyslinski/random_stuff/PBRJ/ref/elevator_wood_1_specular.png"),
            false
        ),
        ImageTexture(
            UVMapping2D(),
            jmfp("/home/jmyslinski/random_stuff/PBRJ/ref/elevator_wood_1_specular.png"),
            true
        ),
        nothing,
        nothing,
        nothing,
        true
    )
    push!(materials, mat_wood_walls)

    name_index = Dict(mat.name => i for (i, mat) in enumerate(materials))
    MATERIAL_REGISTRY[] = MaterialRegistry(materials, name_index)


    ################################
    ####### Constants
    ################################
    WALL_NEGATIVE_EXTENSION = 50.0
    MIN = 0.0
    HEIGHT = 500.0
    DEPTH = 1000.0
    WIDTH = 750.0
    ELEVATOR_HEIGHT = HEIGHT * 6.0 / 7.0
    ELEVATOR_WIDTH = HEIGHT * 0.30
    ELEVATOR_CENTER_1 = DEPTH * 0.7
    ELEVATOR_CENTER_2 = DEPTH * 0.1

    ELEVATOR_TRIM = HEIGHT * 0.05 * 0.75
    ELEVATOR_TRIM_DEPTH = 1.5
    ELEVATOR_DEPTH = 5.0 # WIDTH / 10.0
    ELEVATOR_DOOR_GAP = 3.0

    FLOOR_TRIM_HEIGHT = HEIGHT * 0.05
    FLOOR_TRIM_DEPTH = 1.0

    SILVER_PANEL_CENTER = Pnt2((ELEVATOR_CENTER_1 + ELEVATOR_CENTER_2) / (2 * DEPTH), 0.5)
    SILVER_PANEL_HEIGHT = 50.0
    SILVER_PANEL_WIDTH = 25.0

    CEILING_STUFF_CENTER = WIDTH * 0.5

    L_WIDTH = 0.015
    L_BUFFER = 0.9995

    L1_BOTTOM = 0.25
    L1_MIDDLE = 0.85
    L1_TOP = 0.1

    L2_BOTTOM = 0.35
    L2_MIDDLE = 0.15
    L2_TOP = 0.65

    L3_BOTTOM = 0.6
    L3_MIDDLE = 0.35
    L3_TOP = 0.7

    ################################
    ####### (Alpha) Textures
    ################################

    tex_elevator_door_1_alpha = RectangleProceduralTexture(
        # THESE ARE BACKWARDS BUT IT WORKS?
        Pnt2(
            ELEVATOR_HEIGHT / HEIGHT,
            (ELEVATOR_CENTER_1 - ELEVATOR_WIDTH) / DEPTH, 
        ),
        Pnt2(
            1.0,
            (ELEVATOR_CENTER_1 + ELEVATOR_WIDTH) / DEPTH,
        ),
        1.0,
        0.0,
        "dummy"
    )

    tex_elevator_door_2_alpha = RectangleProceduralTexture(
        # THESE ARE BACKWARDS BUT IT WORKS?
        Pnt2(
            MIN,
            (ELEVATOR_CENTER_2 - ELEVATOR_WIDTH) / DEPTH, 
        ),
        Pnt2(
            ELEVATOR_HEIGHT / HEIGHT,
            (ELEVATOR_CENTER_2 + ELEVATOR_WIDTH) / DEPTH,
        ),
        1.0,
        0.0,
        "dummy"
    )
    
    text_elevator_door_both_alpha = MixAddTexture(
        tex_elevator_door_1_alpha,
        tex_elevator_door_2_alpha,
        "text_elevator_door_both_alpha"
    )
    push!(textures, text_elevator_door_both_alpha)

    name_index = Dict(mat.name => i for (i, mat) in enumerate(textures))
    ALPHA_TEXTURE_REGISTRY[] = AlphaTextureRegistry(textures, name_index)
    

    ################################
    ####### ShapeCores
    ################################
    identity_shape_core = ShapeCore(
        Translate(Pnt3(0.0)),
        Translate(Pnt3(0.0)),
        false,
        false
    )

    identity_shape_core_rev = ShapeCore(
        Translate(Pnt3(0.0)),
        Translate(Pnt3(0.0)),
        true,
        false
    )

    ################################
    ####### Ceiling ball
    ################################
    lil_ball_t = Translate(Pnt3(CEILING_STUFF_CENTER, HEIGHT, DEPTH * 0.9))
    lil_ball = Sphere(
        ShapeCore(
            lil_ball_t,
            Inv(lil_ball_t),
            false,
            false
        ),
        50.0
    )
    push!(primitives, Primitive(lil_ball, "mat_black_shiny", nothing))

    ################################
    ####### Silver Panels
    ################################

    left_silver_panel = Box(
        identity_shape_core, 
        Pnt3(MIN - FLOOR_TRIM_DEPTH, HEIGHT * SILVER_PANEL_CENTER.y - SILVER_PANEL_HEIGHT / 2, DEPTH * SILVER_PANEL_CENTER.x - SILVER_PANEL_WIDTH / 2),
        Pnt3(MIN + FLOOR_TRIM_DEPTH, HEIGHT * SILVER_PANEL_CENTER.y + SILVER_PANEL_HEIGHT / 2, DEPTH * SILVER_PANEL_CENTER.x + SILVER_PANEL_WIDTH / 2),
        "mat_red"
    )
    for prim in left_silver_panel
        push!(primitives, prim)
    end

    right_silver_panel = Box(
        identity_shape_core, 
        Pnt3(WIDTH - FLOOR_TRIM_DEPTH, HEIGHT * SILVER_PANEL_CENTER.y - SILVER_PANEL_HEIGHT / 2, DEPTH * SILVER_PANEL_CENTER.x - SILVER_PANEL_WIDTH / 2),
        Pnt3(WIDTH + FLOOR_TRIM_DEPTH, HEIGHT * SILVER_PANEL_CENTER.y + SILVER_PANEL_HEIGHT / 2, DEPTH * SILVER_PANEL_CENTER.x + SILVER_PANEL_WIDTH / 2),
        "mat_red"
    )
    for prim in right_silver_panel
        push!(primitives, prim)
    end


    ################################
    ####### FLOOR 
    ################################
    floor = BilinearPatchGenerator(
        identity_shape_core,
        1,
        Pnt3[
            Pnt3(MIN-300,   MIN, MIN), 
            Pnt3(WIDTH+300, MIN, MIN),
            Pnt3(MIN-300,   MIN, DEPTH), 
            Pnt3(WIDTH+300, MIN, DEPTH)
        ],
        Int64[1, 2, 3, 4],
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
    )
    for patch in floor
        push!(primitives, Primitive(patch, "mat_concrete", nothing))
    end
    floor_negative_extension = BilinearPatchGenerator(
        identity_shape_core,
        1,
        Pnt3[
            Pnt3(MIN-300,   MIN, MIN - WALL_NEGATIVE_EXTENSION), 
            Pnt3(WIDTH+300, MIN, MIN - WALL_NEGATIVE_EXTENSION),
            Pnt3(MIN-300,   MIN, MIN), 
            Pnt3(WIDTH+300, MIN, MIN)
        ],
        Int64[1, 2, 3, 4],
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
    )
    for patch in floor_negative_extension
        push!(primitives, Primitive(patch, "mat_concrete", nothing))
    end

    # TESTING
    # sphere_t = Translate(Pnt3(WIDTH / 2.0, HEIGHT / 2.0, DEPTH / 2.0))
    # sphere = Sphere(
    #     ShapeCore(
    #         sphere_t,
    #         Inv(sphere_t),
    #         false,
    #         false
    #     ),
    #     HEIGHT / 6.0
    # )
    # alight = DiffuseAreaLight(
    #     spectrum_from_float(15.0, 15.0, 15.0, Illuminant),
    #     sphere,
    #     false # NOT two sided
    # )
    # push!(lights, alight)
    # push!(primitives, Primitive(sphere, "mat_white", alight))

    ################################
    ####### CEILING 
    ################################
    ceiling = BilinearPatchGenerator(
        identity_shape_core,
        1,
        Pnt3[
            Pnt3(MIN,   HEIGHT, MIN),
            Pnt3(WIDTH, HEIGHT, MIN),
            Pnt3(MIN,   HEIGHT, DEPTH),
            Pnt3(WIDTH, HEIGHT, DEPTH)
        ],
        Int64[1, 2, 3, 4],
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
    )
    for patch in ceiling
        push!(primitives, Primitive(patch, "mat_gray", nothing))
    end
    ceiling_negative_extension = BilinearPatchGenerator(
        identity_shape_core,
        1,
        Pnt3[
            Pnt3(MIN,   HEIGHT, MIN - WALL_NEGATIVE_EXTENSION),
            Pnt3(WIDTH, HEIGHT, MIN - WALL_NEGATIVE_EXTENSION),
            Pnt3(MIN,   HEIGHT, MIN),
            Pnt3(WIDTH, HEIGHT, MIN)
        ],
        Int64[1, 2, 3, 4],
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
    )
    for patch in ceiling_negative_extension
        push!(primitives, Primitive(patch, "mat_gray", nothing))
    end

    ################################
    ####### BACK WALL
    ################################
    backwall = BilinearPatchGenerator(
        identity_shape_core,
        1,
        Pnt3[
            Pnt3(MIN,   MIN,    DEPTH),
            Pnt3(WIDTH, MIN,    DEPTH),
            Pnt3(MIN,   HEIGHT, DEPTH),
            Pnt3(WIDTH, HEIGHT, DEPTH)],
        Int64[1, 2, 3, 4],
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
    )
    for patch in backwall
        push!(primitives, Primitive(patch, "mat_gray", nothing))
    end
    backwall_trim = BilinearPatchGenerator(
        identity_shape_core,
        1,
        Pnt3[
            Pnt3(MIN,   MIN,               DEPTH-FLOOR_TRIM_DEPTH),
            Pnt3(WIDTH, MIN,               DEPTH-FLOOR_TRIM_DEPTH),
            Pnt3(MIN,   FLOOR_TRIM_HEIGHT, DEPTH-FLOOR_TRIM_DEPTH),
            Pnt3(WIDTH, FLOOR_TRIM_HEIGHT, DEPTH-FLOOR_TRIM_DEPTH)],
        Int64[1, 2, 3, 4],
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
    )
    for patch in backwall_trim
        push!(primitives, Primitive(patch, "mat_black", nothing))
    end
    backwall_trim2 = BilinearPatchGenerator(
        identity_shape_core,
        1,
        Pnt3[
            Pnt3(MIN,   FLOOR_TRIM_HEIGHT, DEPTH-FLOOR_TRIM_DEPTH),
            Pnt3(WIDTH, FLOOR_TRIM_HEIGHT, DEPTH-FLOOR_TRIM_DEPTH),
            Pnt3(MIN,   FLOOR_TRIM_HEIGHT, DEPTH),
            Pnt3(WIDTH, FLOOR_TRIM_HEIGHT, DEPTH)
        ],
        Int64[1, 2, 3, 4],
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
    )
    for patch in backwall_trim2
        push!(primitives, Primitive(patch, "mat_gray", nothing))
    end

    ################################
    ####### LEFTWALL
    ################################
    leftwall = BilinearPatchGenerator(
        identity_shape_core,
        1,
        Pnt3[
            Pnt3(MIN, MIN,    MIN),
            Pnt3(MIN, HEIGHT, MIN),
            Pnt3(MIN, MIN,    DEPTH),
            Pnt3(MIN, HEIGHT, DEPTH)
        ],
        Int64[1, 2, 3, 4],
        nothing,
        nothing,
        nothing,
        nothing,
        "text_elevator_door_both_alpha",
    )
    for patch in leftwall
        push!(primitives, Primitive(patch, "mat_gray", nothing))
    end
    leftwall_negative_extension = BilinearPatchGenerator(
        identity_shape_core,
        1,
        Pnt3[
            Pnt3(MIN, MIN,    MIN - WALL_NEGATIVE_EXTENSION),
            Pnt3(MIN, HEIGHT, MIN - WALL_NEGATIVE_EXTENSION),
            Pnt3(MIN, MIN,    MIN),
            Pnt3(MIN, HEIGHT, MIN)
        ],
        Int64[1, 2, 3, 4],
        nothing,
        nothing,
        nothing,
        nothing,
        nothing
    )
    for patch in leftwall_negative_extension
        push!(primitives, Primitive(patch, "mat_gray", nothing))
    end
    
    # leftwall_top = BilinearPatchGenerator(
    #     identity_shape_core,
    #     1,
    #     Pnt3[
    #         Pnt3(MIN, ELEVATOR_HEIGHT,    MIN),
    #         Pnt3(MIN, HEIGHT,             MIN),
    #         Pnt3(MIN, ELEVATOR_HEIGHT,    DEPTH),
    #         Pnt3(MIN, HEIGHT,             DEPTH)
    #     ],
    #     Int64[1, 2, 3, 4],
    #     nothing,
    #     nothing,
    #     nothing,
    #     nothing,
    #     nothing,
    # )
    # for patch in leftwall_top
    #     push!(primitives, Primitive(patch, "mat_gray", nothing))
    # end
    # leftwall_bottom_1 = BilinearPatchGenerator(
    #     identity_shape_core,
    #     1,
    #     Pnt3[
    #         Pnt3(MIN, MIN,    ELEVATOR_CENTER_1+ELEVATOR_WIDTH/2),
    #         Pnt3(MIN, HEIGHT, ELEVATOR_CENTER_1+ELEVATOR_WIDTH/2),
    #         Pnt3(MIN, MIN,    DEPTH),
    #         Pnt3(MIN, HEIGHT, DEPTH)
    #     ],
    #     Int64[1, 2, 3, 4],
    #     nothing,
    #     nothing,
    #     nothing,
    #     nothing,
    #     nothing,
    # )
    # for patch in leftwall_bottom_1
    #     push!(primitives, Primitive(patch, "mat_gray", nothing))
    # end
    leftwall_bottom1_trim = BilinearPatchGenerator(
        identity_shape_core,
        1,
        Pnt3[
            Pnt3(MIN+FLOOR_TRIM_DEPTH, MIN,               ELEVATOR_CENTER_1+ELEVATOR_WIDTH/2),
            Pnt3(MIN+FLOOR_TRIM_DEPTH, FLOOR_TRIM_HEIGHT, ELEVATOR_CENTER_1+ELEVATOR_WIDTH/2),
            Pnt3(MIN+FLOOR_TRIM_DEPTH, MIN,               DEPTH),
            Pnt3(MIN+FLOOR_TRIM_DEPTH, FLOOR_TRIM_HEIGHT, DEPTH)
        ],
        Int64[1, 2, 3, 4],
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
    )
    for patch in leftwall_bottom1_trim
        push!(primitives, Primitive(patch, "mat_black", nothing))
    end
    leftwall_bottom1_trim2 = BilinearPatchGenerator(
        identity_shape_core,
        1,
        Pnt3[
            Pnt3(MIN,                  FLOOR_TRIM_HEIGHT, ELEVATOR_CENTER_1+ELEVATOR_WIDTH/2),
            Pnt3(MIN+FLOOR_TRIM_DEPTH, FLOOR_TRIM_HEIGHT, ELEVATOR_CENTER_1+ELEVATOR_WIDTH/2),
            Pnt3(MIN,                  FLOOR_TRIM_HEIGHT, DEPTH),
            Pnt3(MIN+FLOOR_TRIM_DEPTH, FLOOR_TRIM_HEIGHT, DEPTH)
        ],
        Int64[1, 2, 3, 4],
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
    )
    for patch in leftwall_bottom1_trim2
        push!(primitives, Primitive(patch, "mat_black", nothing))
    end
    # leftwall_bottom_2 = BilinearPatchGenerator(
    #     identity_shape_core,
    #     1,
    #     Pnt3[
    #         Pnt3(MIN, MIN,    ELEVATOR_CENTER_2+ELEVATOR_WIDTH/2),
    #         Pnt3(MIN, HEIGHT, ELEVATOR_CENTER_2+ELEVATOR_WIDTH/2),
    #         Pnt3(MIN, MIN,    ELEVATOR_CENTER_1-ELEVATOR_WIDTH/2),
    #         Pnt3(MIN, HEIGHT, ELEVATOR_CENTER_1-ELEVATOR_WIDTH/2)
    #     ],
    #     Int64[1, 2, 3, 4],
    #     nothing,
    #     nothing,
    #     nothing,
    #     nothing,
    #     nothing,
    # )
    # for patch in leftwall_bottom_2
    #     push!(primitives, Primitive(patch, "mat_gray", nothing))
    # end
    leftwall_bottom2_trim = BilinearPatchGenerator(
        identity_shape_core,
        1,
        Pnt3[
            Pnt3(MIN+FLOOR_TRIM_DEPTH, MIN,               ELEVATOR_CENTER_2+ELEVATOR_WIDTH/2),
            Pnt3(MIN+FLOOR_TRIM_DEPTH, FLOOR_TRIM_HEIGHT, ELEVATOR_CENTER_2+ELEVATOR_WIDTH/2),
            Pnt3(MIN+FLOOR_TRIM_DEPTH, MIN,               ELEVATOR_CENTER_1-ELEVATOR_WIDTH/2),
            Pnt3(MIN+FLOOR_TRIM_DEPTH, FLOOR_TRIM_HEIGHT, ELEVATOR_CENTER_1-ELEVATOR_WIDTH/2)
        ],
        Int64[1, 2, 3, 4],
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
    )
    for patch in leftwall_bottom2_trim
        push!(primitives, Primitive(patch, "mat_black", nothing))
    end
    leftwall_bottom2_trim2 = BilinearPatchGenerator(
        identity_shape_core,
        1,
        Pnt3[
            Pnt3(MIN,                  FLOOR_TRIM_HEIGHT, ELEVATOR_CENTER_2+ELEVATOR_WIDTH/2),
            Pnt3(MIN+FLOOR_TRIM_DEPTH, FLOOR_TRIM_HEIGHT, ELEVATOR_CENTER_2+ELEVATOR_WIDTH/2),
            Pnt3(MIN,                  FLOOR_TRIM_HEIGHT, ELEVATOR_CENTER_1-ELEVATOR_WIDTH/2),
            Pnt3(MIN+FLOOR_TRIM_DEPTH, FLOOR_TRIM_HEIGHT, ELEVATOR_CENTER_1-ELEVATOR_WIDTH/2)
        ],
        Int64[1, 2, 3, 4],
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
    )
    for patch in leftwall_bottom2_trim2
        push!(primitives, Primitive(patch, "mat_black", nothing))
    end
    # leftwall_bottom_3 = BilinearPatchGenerator(
    #     identity_shape_core,
    #     1,
    #     Pnt3[
    #         Pnt3(MIN, MIN,    ELEVATOR_CENTER_2-ELEVATOR_WIDTH/2),
    #         Pnt3(MIN, HEIGHT, ELEVATOR_CENTER_2-ELEVATOR_WIDTH/2),
    #         Pnt3(MIN, MIN,    MIN),
    #         Pnt3(MIN, HEIGHT, MIN)
    #     ],
    #     Int64[1, 2, 3, 4],
    #     nothing,
    #     nothing,
    #     nothing,
    #     nothing,
    #     nothing,
    # )
    # for patch in leftwall_bottom_3
    #     push!(primitives, Primitive(patch, "mat_gray", nothing))
    # end
    leftwall_bottom3_trim = BilinearPatchGenerator(
        identity_shape_core,
        1,
        Pnt3[
            Pnt3(MIN+FLOOR_TRIM_DEPTH, MIN,               ELEVATOR_CENTER_2-ELEVATOR_WIDTH/2),
            Pnt3(MIN+FLOOR_TRIM_DEPTH, FLOOR_TRIM_HEIGHT, ELEVATOR_CENTER_2-ELEVATOR_WIDTH/2),
            Pnt3(MIN+FLOOR_TRIM_DEPTH, MIN,               MIN),
            Pnt3(MIN+FLOOR_TRIM_DEPTH, FLOOR_TRIM_HEIGHT, MIN)
        ],
        Int64[1, 2, 3, 4],
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
    )
    for patch in leftwall_bottom3_trim
        push!(primitives, Primitive(patch, "mat_black", nothing))
    end
    leftwall_bottom3_trim2 = BilinearPatchGenerator(
        identity_shape_core,
        1,
        Pnt3[
            Pnt3(MIN,                  FLOOR_TRIM_HEIGHT, ELEVATOR_CENTER_2-ELEVATOR_WIDTH/2),
            Pnt3(MIN+FLOOR_TRIM_DEPTH, FLOOR_TRIM_HEIGHT, ELEVATOR_CENTER_2-ELEVATOR_WIDTH/2),
            Pnt3(MIN,                  FLOOR_TRIM_HEIGHT, MIN),
            Pnt3(MIN+FLOOR_TRIM_DEPTH, FLOOR_TRIM_HEIGHT, MIN)
        ],
        Int64[1, 2, 3, 4],
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
    )
    for patch in leftwall_bottom3_trim2
        push!(primitives, Primitive(patch, "mat_black", nothing))
    end

    ################################
    ####### LEFT ELEVATORS
    ################################
    left_elevator_1_top = Box(
        identity_shape_core, 
        Pnt3(MIN - ELEVATOR_DEPTH,      ELEVATOR_HEIGHT,                 ELEVATOR_CENTER_1 - ELEVATOR_WIDTH/2),
        Pnt3(MIN + ELEVATOR_TRIM_DEPTH, ELEVATOR_HEIGHT + ELEVATOR_TRIM, ELEVATOR_CENTER_1 + ELEVATOR_WIDTH/2),
        "mat_red"
    )
    for prim in left_elevator_1_top
        push!(primitives, prim)
    end

    left_elevator_1_left = Box(
        identity_shape_core, 
        Pnt3(MIN - ELEVATOR_DEPTH,      MIN,                             ELEVATOR_CENTER_1 - ELEVATOR_WIDTH/2),
        Pnt3(MIN + ELEVATOR_TRIM_DEPTH, ELEVATOR_HEIGHT + ELEVATOR_TRIM, ELEVATOR_CENTER_1 - ELEVATOR_WIDTH/2 + ELEVATOR_TRIM),
        "mat_red"
    )
    for prim in left_elevator_1_left
        push!(primitives, prim)
    end

    left_elevator_1_right = Box(
        identity_shape_core, 
        Pnt3(MIN - ELEVATOR_DEPTH,      MIN,                             ELEVATOR_CENTER_1 + ELEVATOR_WIDTH/2),
        Pnt3(MIN + ELEVATOR_TRIM_DEPTH, ELEVATOR_HEIGHT + ELEVATOR_TRIM, ELEVATOR_CENTER_1 + ELEVATOR_WIDTH/2 + ELEVATOR_TRIM),
        "mat_red"
    )
    for prim in left_elevator_1_right
        push!(primitives, prim)
    end

    left_elevator_1_door_1 = BilinearPatchGenerator(
        identity_shape_core,
        1,
        Pnt3[
            Pnt3(MIN - ELEVATOR_DEPTH, MIN,             ELEVATOR_CENTER_1 - ELEVATOR_WIDTH/2),
            Pnt3(MIN - ELEVATOR_DEPTH, ELEVATOR_HEIGHT, ELEVATOR_CENTER_1 - ELEVATOR_WIDTH/2),
            Pnt3(MIN - ELEVATOR_DEPTH, MIN,             ELEVATOR_CENTER_1 - ELEVATOR_DOOR_GAP/2),
            Pnt3(MIN - ELEVATOR_DEPTH, ELEVATOR_HEIGHT, ELEVATOR_CENTER_1 - ELEVATOR_DOOR_GAP/2)
        ],
        Int64[1, 2, 3, 4],
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
    )
    for patch in left_elevator_1_door_1
        push!(primitives, Primitive(patch, "mat_red", nothing))
    end

    left_elevator_1_door_2 = BilinearPatchGenerator(
        identity_shape_core,
        1,
        Pnt3[
            Pnt3(MIN - ELEVATOR_DEPTH, MIN,             ELEVATOR_CENTER_1 + ELEVATOR_DOOR_GAP/2),
            Pnt3(MIN - ELEVATOR_DEPTH, ELEVATOR_HEIGHT, ELEVATOR_CENTER_1 + ELEVATOR_DOOR_GAP/2),
            Pnt3(MIN - ELEVATOR_DEPTH, MIN,             ELEVATOR_CENTER_1 + ELEVATOR_WIDTH/2),
            Pnt3(MIN - ELEVATOR_DEPTH, ELEVATOR_HEIGHT, ELEVATOR_CENTER_1 + ELEVATOR_WIDTH/2)
        ],
        Int64[1, 2, 3, 4],
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
    )
    for patch in left_elevator_1_door_2
        push!(primitives, Primitive(patch, "mat_red", nothing))
    end

    left_elevator_2_top = Box(
        identity_shape_core, 
        Pnt3(MIN - ELEVATOR_DEPTH,      ELEVATOR_HEIGHT,                 ELEVATOR_CENTER_2 - ELEVATOR_WIDTH/2),
        Pnt3(MIN + ELEVATOR_TRIM_DEPTH, ELEVATOR_HEIGHT + ELEVATOR_TRIM, ELEVATOR_CENTER_2 + ELEVATOR_WIDTH/2),
        "mat_red"
    )
    for prim in left_elevator_2_top
        push!(primitives, prim)
    end

    left_elevator_2_left = Box(
        identity_shape_core, 
        Pnt3(MIN - ELEVATOR_DEPTH,      MIN,                             ELEVATOR_CENTER_2 - ELEVATOR_WIDTH/2),
        Pnt3(MIN + ELEVATOR_TRIM_DEPTH, ELEVATOR_HEIGHT + ELEVATOR_TRIM, ELEVATOR_CENTER_2 - ELEVATOR_WIDTH/2 + ELEVATOR_TRIM),
        "mat_red"
    )
    for prim in left_elevator_2_left
        push!(primitives, prim)
    end

    left_elevator_2_right = Box(
        identity_shape_core, 
        Pnt3(MIN - ELEVATOR_DEPTH,      MIN,                             ELEVATOR_CENTER_2 + ELEVATOR_WIDTH/2),
        Pnt3(MIN + ELEVATOR_TRIM_DEPTH, ELEVATOR_HEIGHT + ELEVATOR_TRIM, ELEVATOR_CENTER_2 + ELEVATOR_WIDTH/2 + ELEVATOR_TRIM),
        "mat_red"
    )
    for prim in left_elevator_2_right
        push!(primitives, prim)
    end

    left_elevator_2_door_1 = BilinearPatchGenerator(
        identity_shape_core,
        1,
        Pnt3[
            Pnt3(MIN - ELEVATOR_DEPTH, MIN,             ELEVATOR_CENTER_2 - ELEVATOR_WIDTH/2),
            Pnt3(MIN - ELEVATOR_DEPTH, ELEVATOR_HEIGHT, ELEVATOR_CENTER_2 - ELEVATOR_WIDTH/2),
            Pnt3(MIN - ELEVATOR_DEPTH, MIN,             ELEVATOR_CENTER_2 - ELEVATOR_DOOR_GAP/2),
            Pnt3(MIN - ELEVATOR_DEPTH, ELEVATOR_HEIGHT, ELEVATOR_CENTER_2 - ELEVATOR_DOOR_GAP/2)
        ],
        Int64[1, 2, 3, 4],
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
    )
    for patch in left_elevator_2_door_1
        push!(primitives, Primitive(patch, "mat_red", nothing))
    end

    left_elevator_2_door_2 = BilinearPatchGenerator(
        identity_shape_core,
        1,
        Pnt3[
            Pnt3(MIN - ELEVATOR_DEPTH, MIN,             ELEVATOR_CENTER_2 + ELEVATOR_DOOR_GAP/2),
            Pnt3(MIN - ELEVATOR_DEPTH, ELEVATOR_HEIGHT, ELEVATOR_CENTER_2 + ELEVATOR_DOOR_GAP/2),
            Pnt3(MIN - ELEVATOR_DEPTH, MIN,             ELEVATOR_CENTER_2 + ELEVATOR_WIDTH/2),
            Pnt3(MIN - ELEVATOR_DEPTH, ELEVATOR_HEIGHT, ELEVATOR_CENTER_2 + ELEVATOR_WIDTH/2)
        ],
        Int64[1, 2, 3, 4],
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
    )
    for patch in left_elevator_2_door_2
        push!(primitives, Primitive(patch, "mat_red", nothing))
    end

    ################################
    ####### RIGHT WALL
    ################################
    rightwall = BilinearPatchGenerator(
        identity_shape_core,
        1,
        Pnt3[
            Pnt3(WIDTH, MIN,    MIN),
            Pnt3(WIDTH, HEIGHT, MIN),
            Pnt3(WIDTH, MIN,    DEPTH),
            Pnt3(WIDTH, HEIGHT, DEPTH)
        ],
        Int64[1, 2, 3, 4],
        nothing,
        nothing,
        nothing,
        nothing,
        "text_elevator_door_both_alpha"
    )
    for patch in rightwall
        push!(primitives, Primitive(patch, "mat_gray", nothing))
    end
    rightwall_negative_extension = BilinearPatchGenerator(
        identity_shape_core,
        1,
        Pnt3[
            Pnt3(WIDTH, MIN,    MIN - WALL_NEGATIVE_EXTENSION),
            Pnt3(WIDTH, HEIGHT, MIN - WALL_NEGATIVE_EXTENSION),
            Pnt3(WIDTH, MIN,    MIN),
            Pnt3(WIDTH, HEIGHT, MIN)
        ],
        Int64[1, 2, 3, 4],
        nothing,
        nothing,
        nothing,
        nothing,
        nothing
    )
    for patch in rightwall_negative_extension
        push!(primitives, Primitive(patch, "mat_gray", nothing))
    end

    # rightwall_top = BilinearPatchGenerator(
    #     identity_shape_core,
    #     1,
    #     Pnt3[
    #         Pnt3(WIDTH, ELEVATOR_HEIGHT,    MIN),
    #         Pnt3(WIDTH, HEIGHT,             MIN),
    #         Pnt3(WIDTH, ELEVATOR_HEIGHT,    DEPTH),
    #         Pnt3(WIDTH, HEIGHT,             DEPTH)
    #     ],
    #     Int64[1, 2, 3, 4],
    #     nothing,
    #     nothing,
    #     nothing,
    #     nothing,
    #     nothing,
    # )
    # for patch in rightwall_top
    #     push!(primitives, Primitive(patch, "mat_gray", nothing))
    # end
    # rightwall_bottom_1 = BilinearPatchGenerator(
    #     identity_shape_core,
    #     1,
    #     Pnt3[
    #         Pnt3(WIDTH, MIN,    ELEVATOR_CENTER_1+ELEVATOR_WIDTH/2),
    #         Pnt3(WIDTH, HEIGHT, ELEVATOR_CENTER_1+ELEVATOR_WIDTH/2),
    #         Pnt3(WIDTH, MIN,    DEPTH),
    #         Pnt3(WIDTH, HEIGHT, DEPTH)
    #     ],
    #     Int64[1, 2, 3, 4],
    #     nothing,
    #     nothing,
    #     nothing,
    #     nothing,
    #     nothing,
    # )
    # for patch in rightwall_bottom_1
    #     push!(primitives, Primitive(patch, "mat_gray", nothing))
    # end
    rightwall_bottom_1_trim = BilinearPatchGenerator(
        identity_shape_core,
        1,
        Pnt3[
            Pnt3(WIDTH-FLOOR_TRIM_DEPTH, MIN,               ELEVATOR_CENTER_1+ELEVATOR_WIDTH/2),
            Pnt3(WIDTH-FLOOR_TRIM_DEPTH, FLOOR_TRIM_HEIGHT, ELEVATOR_CENTER_1+ELEVATOR_WIDTH/2),
            Pnt3(WIDTH-FLOOR_TRIM_DEPTH, MIN,               DEPTH),
            Pnt3(WIDTH-FLOOR_TRIM_DEPTH, FLOOR_TRIM_HEIGHT, DEPTH)
        ],
        Int64[1, 2, 3, 4],
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
    )
    for patch in rightwall_bottom_1_trim
        push!(primitives, Primitive(patch, "mat_black", nothing))
    end
    rightwall_bottom_1_trim2 = BilinearPatchGenerator(
        identity_shape_core,
        1,
        Pnt3[
            Pnt3(WIDTH,                  FLOOR_TRIM_HEIGHT, ELEVATOR_CENTER_1+ELEVATOR_WIDTH/2),
            Pnt3(WIDTH-FLOOR_TRIM_DEPTH, FLOOR_TRIM_HEIGHT, ELEVATOR_CENTER_1+ELEVATOR_WIDTH/2),
            Pnt3(WIDTH,                  FLOOR_TRIM_HEIGHT, DEPTH),
            Pnt3(WIDTH-FLOOR_TRIM_DEPTH, FLOOR_TRIM_HEIGHT, DEPTH)
        ],
        Int64[1, 2, 3, 4],
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
    )
    for patch in rightwall_bottom_1_trim2
        push!(primitives, Primitive(patch, "mat_black", nothing))
    end

    # rightwall_bottom_2 = BilinearPatchGenerator(
    #     identity_shape_core,
    #     1,
    #     Pnt3[
    #         Pnt3(WIDTH, MIN,    ELEVATOR_CENTER_2+ELEVATOR_WIDTH/2),
    #         Pnt3(WIDTH, HEIGHT, ELEVATOR_CENTER_2+ELEVATOR_WIDTH/2),
    #         Pnt3(WIDTH, MIN,    ELEVATOR_CENTER_1-ELEVATOR_WIDTH/2),
    #         Pnt3(WIDTH, HEIGHT, ELEVATOR_CENTER_1-ELEVATOR_WIDTH/2)
    #     ],
    #     Int64[1, 2, 3, 4],
    #     nothing,
    #     nothing,
    #     nothing,
    #     nothing,
    #     nothing,
    # )
    # for patch in rightwall_bottom_2
    #     push!(primitives, Primitive(patch, "mat_gray", nothing))
    # end
    rightwall_bottom_2_trim = BilinearPatchGenerator(
        identity_shape_core,
        1,
        Pnt3[
            Pnt3(WIDTH-FLOOR_TRIM_DEPTH, MIN,               ELEVATOR_CENTER_2+ELEVATOR_WIDTH/2),
            Pnt3(WIDTH-FLOOR_TRIM_DEPTH, FLOOR_TRIM_HEIGHT, ELEVATOR_CENTER_2+ELEVATOR_WIDTH/2),
            Pnt3(WIDTH-FLOOR_TRIM_DEPTH, MIN,               ELEVATOR_CENTER_1-ELEVATOR_WIDTH/2),
            Pnt3(WIDTH-FLOOR_TRIM_DEPTH, FLOOR_TRIM_HEIGHT, ELEVATOR_CENTER_1-ELEVATOR_WIDTH/2)
        ],
        Int64[1, 2, 3, 4],
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
    )
    for patch in rightwall_bottom_2_trim
        push!(primitives, Primitive(patch, "mat_black", nothing))
    end
    rightwall_bottom_2_trim2 = BilinearPatchGenerator(
        identity_shape_core,
        1,
        Pnt3[
            Pnt3(WIDTH,                  FLOOR_TRIM_HEIGHT, ELEVATOR_CENTER_2+ELEVATOR_WIDTH/2),
            Pnt3(WIDTH-FLOOR_TRIM_DEPTH, FLOOR_TRIM_HEIGHT, ELEVATOR_CENTER_2+ELEVATOR_WIDTH/2),
            Pnt3(WIDTH,                  FLOOR_TRIM_HEIGHT, ELEVATOR_CENTER_1-ELEVATOR_WIDTH/2),
            Pnt3(WIDTH+FLOOR_TRIM_DEPTH, FLOOR_TRIM_HEIGHT, ELEVATOR_CENTER_1-ELEVATOR_WIDTH/2)
        ],
        Int64[1, 2, 3, 4],
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
    )
    for patch in rightwall_bottom_2_trim2
        push!(primitives, Primitive(patch, "mat_black", nothing))
    end

    # rightwall_bottom_3 = BilinearPatchGenerator(
    #     identity_shape_core,
    #     1,
    #     Pnt3[
    #         Pnt3(WIDTH, MIN,    ELEVATOR_CENTER_2-ELEVATOR_WIDTH/2),
    #         Pnt3(WIDTH, HEIGHT, ELEVATOR_CENTER_2-ELEVATOR_WIDTH/2),
    #         Pnt3(WIDTH, MIN,    MIN),
    #         Pnt3(WIDTH, HEIGHT, MIN)
    #     ],
    #     Int64[1, 2, 3, 4],
    #     nothing,
    #     nothing,
    #     nothing,
    #     nothing,
    #     nothing,
    # )
    # for patch in rightwall_bottom_3
    #     push!(primitives, Primitive(patch, "mat_gray", nothing))
    # end
    rightwall_bottom3_trim = BilinearPatchGenerator(
        identity_shape_core,
        1,
        Pnt3[
            Pnt3(WIDTH-FLOOR_TRIM_DEPTH, MIN,               ELEVATOR_CENTER_2-ELEVATOR_WIDTH/2),
            Pnt3(WIDTH-FLOOR_TRIM_DEPTH, FLOOR_TRIM_HEIGHT, ELEVATOR_CENTER_2-ELEVATOR_WIDTH/2),
            Pnt3(WIDTH-FLOOR_TRIM_DEPTH, MIN,               MIN),
            Pnt3(WIDTH-FLOOR_TRIM_DEPTH, FLOOR_TRIM_HEIGHT, MIN)
        ],
        Int64[1, 2, 3, 4],
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
    )
    for patch in rightwall_bottom3_trim
        push!(primitives, Primitive(patch, "mat_black", nothing))
    end
    rightwall_bottom3_trim2 = BilinearPatchGenerator(
        identity_shape_core,
        1,
        Pnt3[
            Pnt3(WIDTH,                  FLOOR_TRIM_HEIGHT, ELEVATOR_CENTER_2-ELEVATOR_WIDTH/2),
            Pnt3(WIDTH-FLOOR_TRIM_DEPTH, FLOOR_TRIM_HEIGHT, ELEVATOR_CENTER_2-ELEVATOR_WIDTH/2),
            Pnt3(WIDTH,                  FLOOR_TRIM_HEIGHT, MIN),
            Pnt3(WIDTH-FLOOR_TRIM_DEPTH, FLOOR_TRIM_HEIGHT, MIN)
        ],
        Int64[1, 2, 3, 4],
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
    )
    for patch in rightwall_bottom3_trim2
        push!(primitives, Primitive(patch, "mat_black", nothing))
    end

    ################################
    ####### RIGHT ELEVATORS
    ################################
    right_elevator_1_top = Box(
        identity_shape_core, 
        Pnt3(WIDTH - ELEVATOR_TRIM_DEPTH, ELEVATOR_HEIGHT, ELEVATOR_CENTER_1 - ELEVATOR_WIDTH/2),
        Pnt3(WIDTH + ELEVATOR_DEPTH,                       ELEVATOR_HEIGHT + ELEVATOR_TRIM, ELEVATOR_CENTER_1 + ELEVATOR_WIDTH/2),
        "mat_red"
    )
    for prim in right_elevator_1_top
        push!(primitives, prim)
    end

    right_elevator_1_left = Box(
        identity_shape_core, 
        Pnt3(WIDTH - ELEVATOR_TRIM_DEPTH, MIN,                             ELEVATOR_CENTER_1 - ELEVATOR_WIDTH/2),
        Pnt3(WIDTH + ELEVATOR_DEPTH,      ELEVATOR_HEIGHT + ELEVATOR_TRIM, ELEVATOR_CENTER_1 - ELEVATOR_WIDTH/2 + ELEVATOR_TRIM),
        "mat_red"
    )
    for prim in right_elevator_1_left
        push!(primitives, prim)
    end

    right_elevator_1_right = Box(
        identity_shape_core, 
        Pnt3(WIDTH - ELEVATOR_TRIM_DEPTH, MIN,                             ELEVATOR_CENTER_1 + ELEVATOR_WIDTH/2),
        Pnt3(WIDTH + ELEVATOR_DEPTH,      ELEVATOR_HEIGHT + ELEVATOR_TRIM, ELEVATOR_CENTER_1 + ELEVATOR_WIDTH/2 + ELEVATOR_TRIM),
        "mat_red"
    )
    for prim in right_elevator_1_right
        push!(primitives, prim)
    end

    right_elevator_1_door_1 = BilinearPatchGenerator(
        identity_shape_core,
        1,
        Pnt3[
            Pnt3(WIDTH + ELEVATOR_DEPTH, MIN,             ELEVATOR_CENTER_1 - ELEVATOR_WIDTH/2),
            Pnt3(WIDTH + ELEVATOR_DEPTH, ELEVATOR_HEIGHT, ELEVATOR_CENTER_1 - ELEVATOR_WIDTH/2),
            Pnt3(WIDTH + ELEVATOR_DEPTH, MIN,             ELEVATOR_CENTER_1 - ELEVATOR_DOOR_GAP/2),
            Pnt3(WIDTH + ELEVATOR_DEPTH, ELEVATOR_HEIGHT, ELEVATOR_CENTER_1 - ELEVATOR_DOOR_GAP/2)
        ],
        Int64[1, 2, 3, 4],
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
    )
    for patch in right_elevator_1_door_1
        push!(primitives, Primitive(patch, "mat_red", nothing))
    end

    right_elevator_1_door_2 = BilinearPatchGenerator(
        identity_shape_core,
        1,
        Pnt3[
            Pnt3(WIDTH + ELEVATOR_DEPTH, MIN,             ELEVATOR_CENTER_1 + ELEVATOR_DOOR_GAP/2),
            Pnt3(WIDTH + ELEVATOR_DEPTH, ELEVATOR_HEIGHT, ELEVATOR_CENTER_1 + ELEVATOR_DOOR_GAP/2),
            Pnt3(WIDTH + ELEVATOR_DEPTH, MIN,             ELEVATOR_CENTER_1 + ELEVATOR_WIDTH/2),
            Pnt3(WIDTH + ELEVATOR_DEPTH, ELEVATOR_HEIGHT, ELEVATOR_CENTER_1 + ELEVATOR_WIDTH/2)
        ],
        Int64[1, 2, 3, 4],
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
    )
    for patch in right_elevator_1_door_2
        push!(primitives, Primitive(patch, "mat_red", nothing))
    end

    right_elevator_2_top = Box(
        identity_shape_core, 
        Pnt3(WIDTH - ELEVATOR_TRIM_DEPTH, ELEVATOR_HEIGHT,                 ELEVATOR_CENTER_2 - ELEVATOR_WIDTH/2),
        Pnt3(WIDTH + ELEVATOR_DEPTH,      ELEVATOR_HEIGHT + ELEVATOR_TRIM, ELEVATOR_CENTER_2 + ELEVATOR_WIDTH/2),
        "mat_red"
    )
    for prim in right_elevator_2_top
        push!(primitives, prim)
    end

    right_elevator_2_left = Box(
        identity_shape_core, 
        Pnt3(WIDTH - ELEVATOR_TRIM_DEPTH, MIN,                             ELEVATOR_CENTER_2 - ELEVATOR_WIDTH/2),
        Pnt3(WIDTH + ELEVATOR_DEPTH,      ELEVATOR_HEIGHT + ELEVATOR_TRIM, ELEVATOR_CENTER_2 - ELEVATOR_WIDTH/2 + ELEVATOR_TRIM),
        "mat_red"
    )
    for prim in right_elevator_2_left
        push!(primitives, prim)
    end

    right_elevator_2_right = Box(
        identity_shape_core, 
        Pnt3(WIDTH - ELEVATOR_TRIM_DEPTH, MIN,                             ELEVATOR_CENTER_2 + ELEVATOR_WIDTH/2),
        Pnt3(WIDTH + ELEVATOR_DEPTH,      ELEVATOR_HEIGHT + ELEVATOR_TRIM, ELEVATOR_CENTER_2 + ELEVATOR_WIDTH/2 + ELEVATOR_TRIM),
        "mat_red"
    )
    for prim in right_elevator_2_right
        push!(primitives, prim)
    end

    right_elevator_2_door_1 = BilinearPatchGenerator(
        identity_shape_core,
        1,
        Pnt3[
            Pnt3(WIDTH + ELEVATOR_DEPTH, MIN,             ELEVATOR_CENTER_2 - ELEVATOR_WIDTH/2),
            Pnt3(WIDTH + ELEVATOR_DEPTH, ELEVATOR_HEIGHT, ELEVATOR_CENTER_2 - ELEVATOR_WIDTH/2),
            Pnt3(WIDTH + ELEVATOR_DEPTH, MIN,             ELEVATOR_CENTER_2 - ELEVATOR_DOOR_GAP/2),
            Pnt3(WIDTH + ELEVATOR_DEPTH, ELEVATOR_HEIGHT, ELEVATOR_CENTER_2 - ELEVATOR_DOOR_GAP/2)
        ],
        Int64[1, 2, 3, 4],
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
    )
    for patch in right_elevator_2_door_1
        push!(primitives, Primitive(patch, "mat_red", nothing))
    end

    right_elevator_2_door_2 = BilinearPatchGenerator(
        identity_shape_core,
        1,
        Pnt3[
            Pnt3(WIDTH + ELEVATOR_DEPTH, MIN,             ELEVATOR_CENTER_2 + ELEVATOR_DOOR_GAP/2),
            Pnt3(WIDTH + ELEVATOR_DEPTH, ELEVATOR_HEIGHT, ELEVATOR_CENTER_2 + ELEVATOR_DOOR_GAP/2),
            Pnt3(WIDTH + ELEVATOR_DEPTH, MIN,             ELEVATOR_CENTER_2 + ELEVATOR_WIDTH/2),
            Pnt3(WIDTH + ELEVATOR_DEPTH, ELEVATOR_HEIGHT, ELEVATOR_CENTER_2 + ELEVATOR_WIDTH/2)
        ],
        Int64[1, 2, 3, 4],
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
    )
    for patch in right_elevator_2_door_2
        push!(primitives, Primitive(patch, "mat_red", nothing))
    end

    ################################
    ####### Light 1
    ################################
    backwall_light1 = BilinearPatchGenerator(
        identity_shape_core_rev,
        1,
        Pnt3[
            Pnt3(WIDTH*L1_BOTTOM,           FLOOR_TRIM_HEIGHT, DEPTH*L_BUFFER), 
            Pnt3(WIDTH*(L1_BOTTOM+L_WIDTH), FLOOR_TRIM_HEIGHT, DEPTH*L_BUFFER), 
            Pnt3(WIDTH*L1_MIDDLE,           HEIGHT,            DEPTH*L_BUFFER), 
            Pnt3(WIDTH*(L1_MIDDLE+L_WIDTH), HEIGHT,            DEPTH*L_BUFFER)
        ],
        Int64[1, 2, 3, 4],
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
    )
    for patch in backwall_light1
        alight = DiffuseAreaLight(
            spectrum_from_float(5.0, 5.0, 5.0, Illuminant),
            patch,
            false # NOT two sided
        )
        push!(lights, alight)
        push!(primitives, Primitive(patch, "mat_white", alight))
    end
    ceiling_light1 = BilinearPatchGenerator(
        identity_shape_core,
        1,
        Pnt3[
            Pnt3(WIDTH*L1_TOP,              HEIGHT*L_BUFFER,     MIN), 
            Pnt3(WIDTH*(L1_TOP+L_WIDTH),    HEIGHT*L_BUFFER,     MIN), 
            Pnt3(WIDTH*L1_MIDDLE,           HEIGHT*L_BUFFER,     DEPTH), 
            Pnt3(WIDTH*(L1_MIDDLE+L_WIDTH), HEIGHT*L_BUFFER,     DEPTH)
        ],
        Int64[1, 2, 3, 4],
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
    )
    for patch in ceiling_light1
        alight = DiffuseAreaLight(
            spectrum_from_float(5.0, 5.0, 5.0, Illuminant),
            patch,
            false # NOT two sided
        )
        push!(lights, alight)
        push!(primitives, Primitive(patch, "mat_white", alight))
    end

    ################################
    ####### Light 2
    ################################
    backwall_light2 = BilinearPatchGenerator(
        identity_shape_core_rev,
        1,
        Pnt3[
            Pnt3(WIDTH*L2_BOTTOM,           FLOOR_TRIM_HEIGHT, DEPTH*L_BUFFER), 
            Pnt3(WIDTH*(L2_BOTTOM+L_WIDTH), FLOOR_TRIM_HEIGHT, DEPTH*L_BUFFER), 
            Pnt3(WIDTH*L2_MIDDLE,           HEIGHT,            DEPTH*L_BUFFER), 
            Pnt3(WIDTH*(L2_MIDDLE+L_WIDTH), HEIGHT,            DEPTH*L_BUFFER)
        ],
        Int64[1, 2, 3, 4],
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
    )
    for patch in backwall_light2
        alight = DiffuseAreaLight(
            spectrum_from_float(5.0, 5.0, 5.0, Illuminant),
            patch,
            false # NOT two sided
        )
        push!(lights, alight)
        push!(primitives, Primitive(patch, "mat_white", alight))
    end
    ceiling_light2 = BilinearPatchGenerator(
        identity_shape_core,
        1,
        Pnt3[
            Pnt3(WIDTH*L2_TOP,              HEIGHT*L_BUFFER,     MIN), 
            Pnt3(WIDTH*(L2_TOP+L_WIDTH),    HEIGHT*L_BUFFER,     MIN), 
            Pnt3(WIDTH*L2_MIDDLE,           HEIGHT*L_BUFFER,     DEPTH), 
            Pnt3(WIDTH*(L2_MIDDLE+L_WIDTH), HEIGHT*L_BUFFER,     DEPTH)
        ],
        Int64[1, 2, 3, 4],
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
    )
    for patch in ceiling_light2
        alight = DiffuseAreaLight(
            spectrum_from_float(5.0, 5.0, 5.0, Illuminant),
            patch,
            false # NOT two sided
        )
        push!(lights, alight)
        push!(primitives, Primitive(patch, "mat_white", alight))
    end

    ################################
    ####### Light 3
    ################################
    backwall_light3 = BilinearPatchGenerator(
        identity_shape_core_rev,
        1,
        Pnt3[
            Pnt3(WIDTH,                     HEIGHT*L3_BOTTOM,           DEPTH*L_BUFFER), 
            Pnt3(WIDTH,                     HEIGHT*(L3_BOTTOM+L_WIDTH), DEPTH*L_BUFFER), 
            Pnt3(WIDTH*L3_MIDDLE,           HEIGHT,                     DEPTH*L_BUFFER), 
            Pnt3(WIDTH*(L3_MIDDLE+L_WIDTH), HEIGHT,                     DEPTH*L_BUFFER)
        ],
        Int64[1, 2, 3, 4],
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
    )
    for patch in backwall_light3
        alight = DiffuseAreaLight(
            spectrum_from_float(5.0, 5.0, 5.0, Illuminant),
            patch,
            false # NOT two sided
        )
        push!(lights, alight)
        push!(primitives, Primitive(patch, "mat_white", alight))
    end
    ceiling_light3 = BilinearPatchGenerator(
        identity_shape_core,
        1,
        Pnt3[
            Pnt3(WIDTH,                     HEIGHT*L_BUFFER,     DEPTH*L3_TOP), 
            Pnt3(WIDTH,                     HEIGHT*L_BUFFER,     DEPTH*(L3_TOP+L_WIDTH)), 
            Pnt3(WIDTH*L3_MIDDLE,           HEIGHT*L_BUFFER,     DEPTH), 
            Pnt3(WIDTH*(L3_MIDDLE+L_WIDTH), HEIGHT*L_BUFFER,     DEPTH)
        ],
        Int64[1, 2, 3, 4],
        nothing,
        nothing,
        nothing,
        nothing,
        nothing,
    )
    for patch in ceiling_light3
        alight = DiffuseAreaLight(
            spectrum_from_float(5.0, 5.0, 5.0, Illuminant),
            patch,
            false # NOT two sided
        )
        push!(lights, alight)
        push!(primitives, Primitive(patch, "mat_white", alight))
    end

    # instantiate accelerator
    print("\nThere are " * num2str(length(primitives)) * " objects in the scene, building BVH\n")
    @time bvh = BVH(primitives)
    print("Done building BVH\n")

    l_2_w = Rotate(-90.0, Vec3(1,0,0))
    light = InfiniteLight(
        world_bounds(bvh), 
        l_2_w, 
        Spectrum(5.0, 5.0, 5.0), 
        jmfp("/Users/johnmyslinski/Documents/pbrt-v4-scenes/lte-orb/textures/small_rural_road_equiarea.exr"),
        true
    )
    push!(lights, light)

    # Instantiate a Filter
    filter = LanczosSincFilter(Pnt2(0.5, 0.5), 3.0)

    # Instantiate a Filter
    filter = BoxFilter(Pnt2(.5, .5))

    # Instantiate a Film
    film = Film(
        Pnt2i(parsed_args["image-dim"][1], parsed_args["image-dim"][2]),
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
    S = ZSobolSampler(
        parsed_args["samples-per-pixel"], 
        film.full_resolution, 
        Int8(2),
        parsed_args["seed"]
    )
    print("Using " * num2str(S.samples_per_pixel) * " samples per pixel\n")
    
    # Instantiate Scene
    print("There are " * num2str(length(lights)) * " lights in the scene\n")
    scene = Scene(lights, bvh)
    
    # Instantiate an Integrator
    I = BDPTIntegrator(C, S, parsed_args["max-depth"])
    return I, scene
end
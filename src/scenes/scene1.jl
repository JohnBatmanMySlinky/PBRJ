function create_stair_rectangles(
    pMin::Pnt3,
    pMax::Pnt3,
    N::Int,
    axis::Int64,  # Which axis the stairs ascend (1=x, 2=y, 3=z)
    sc::ShapeCore,
    flip_normals::Bool,
    alpha_mask::Maybe{String}
)::Vector{Vector{Triangle}}
    
    stairs = Vector{Vector{Triangle}}()
    
    # Determine the dimensions
    width = pMax - pMin
    
    # Calculate step dimensions
    if axis == 1  # Stairs along X axis
        step_depth = width[1] / N
        step_height = width[3] / N
        
        for i in 0:(N-1)
            # Current step position
            x_start = pMin[1] + i * step_depth
            x_end = pMin[1] + (i + 1) * step_depth
            z_current = pMin[3] + i * step_height
            z_next = pMin[3] + (i + 1) * step_height
            
            # Top surface of step
            top_min = Pnt2(x_start, pMin[2])
            top_max = Pnt2(x_end, pMax[2])
            top = Rectangle(top_min, top_max, z_next, 3, sc, flip_normals, alpha_mask)
            push!(stairs, top)
            
            # Vertical riser (if not the first step)
            riser_min = Pnt2(z_current, pMin[2])
            riser_max = Pnt2(z_next, pMax[2])
            riser = Rectangle(riser_min, riser_max, x_start, 1, sc, flip_normals, alpha_mask)
            push!(stairs, riser)
        end
        
    elseif axis == 2  # Stairs along Y axis
        step_depth = width[2] / N
        step_height = width[3] / N
        
        for i in 0:(N-1)
            y_start = pMin[2] + i * step_depth
            y_end = pMin[2] + (i + 1) * step_depth
            z_current = pMin[3] + i * step_height
            z_next = pMin[3] + (i + 1) * step_height
            
            # Top surface
            top_min = Pnt2(pMin[1], y_start)
            top_max = Pnt2(pMax[1], y_end)
            top = Rectangle(top_min, top_max, z_next, 3, sc, flip_normals, alpha_mask)
            push!(stairs, top)
            
            # Riser
            riser_min = Pnt2(pMin[1], z_current)
            riser_max = Pnt2(pMax[1], z_next)
            riser = Rectangle(riser_min, riser_max, y_start, 2, sc, flip_normals, alpha_mask)
            push!(stairs, riser)
        end
        
    else  # axis == 3, stairs along Z axis
        step_depth = width[3] / N
        step_height = width[2] / N  # Or width[1] depending on desired orientation
        
        for i in 0:(N-1)
            z_start = pMin[3] + i * step_depth
            z_end = pMin[3] + (i + 1) * step_depth
            y_current = pMin[2] + i * step_height
            y_next = pMin[2] + (i + 1) * step_height
            
            # Top surface
            top_min = Pnt2(pMin[1], z_start)
            top_max = Pnt2(pMax[1], z_end)
            top = Rectangle(top_min, top_max, y_next, 2, sc, flip_normals, alpha_mask)
            push!(stairs, top)
            
            # Riser
            riser_min = Pnt2(pMin[1], y_current)
            riser_max = Pnt2(pMax[1], y_next)
            riser = Rectangle(riser_min, riser_max, z_start, 3, sc, flip_normals, alpha_mask)
            push!(stairs, riser)
        end
    end
    
    return stairs
end

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

    mat_gray = Matte(
        "mat_gray",
        ConstantTexture(spectrum_from_float(1.0, 1.0, 0.0)),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_gray)

    mat_pink = Matte(
        "mat_pink",
        ConstantTexture(spectrum_from_float(1.0, 0.0, 0.4)),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_pink)

    mat_concrete = Substrate(
        "mat_concrete",
        ImageTexture(
            UVMapping2D(), 
            jmfp("/Users/johnmyslinski/Documents/PBRJ/ref/Concrete material 3_baseColor.jpeg"), 
            false
        ), # kd
        ImageTexture(
            UVMapping2D(), 
            jmfp("/Users/johnmyslinski/Documents/PBRJ/ref/Concrete material 3_specular.jpeg"), 
            false
        ), # ks
        # ConstantTexture(spectrum_from_float(0.15, 0.15, 0.15)),
        ImageTexture(
            UVMapping2D(), 
            jmfp("/Users/johnmyslinski/Documents/PBRJ/ref/Concrete material 3_roughness.jpeg"), 
            true
        ), # roughness u
        # ConstantTexture(.003),
        ImageTexture(
            UVMapping2D(), 
            jmfp("/Users/johnmyslinski/Documents/PBRJ/ref/Concrete material 3_roughness.jpeg"), 
            true
        ), # roughness v
        # ConstantTexture(.003),
        # ImageTexture(
        #     UVMapping2D(), 
        #     jmfp("/Users/johnmyslinski/Documents/PBRJ/ref/Concrete material 3_ambientOcclusion.jpeg"),
        #     true
        # ), # bump
        nothing,
        true # remap
    )
    push!(materials, mat_concrete)

    mat_metal_door = Metal(
        "mat_metal_door",
        ConstantTexture(spectrum_from_float(0.155, 0.116, 0.138)),
        ConstantTexture(spectrum_from_float(0.482, 0.312, 0.214)),
        nothing,
        ConstantTexture(.001),
        ConstantTexture(.3),
        nothing,
        true
    )
    push!(materials, mat_metal_door)

    ###################################
    ###### GEOMETRICAL CONSTANTS ######
    ###################################

    ceiling_height = 200.0 # ~10ft * 20
    hallway_width = 160.0 # ~8ft * 20
    hallway_width_extra = 20.0
    stairs_total_width = 120.0 # ~6ft * 20
    stairs_offset = 275.0
    stairs_depth = stairs_total_width * 3
    elevator_total_width = 80.0
    elevator_offset = 100.0
    elevator_door_gap = 3.0
    elevator_depth = 15.0
    pillar_width_1 = 60.0 # ~4.5ft * 20
    pillar_width_2 = 20.0 # ~ 1.5ft * 20
    pillar_edge_thickness = 2.0
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
        push!(primitives2, Primitive(tri, "mat_concrete", nothing))
    end

    ################# CEILING
    # Opting for an OBJ because my alpha map hack was fucking with the lighting!!!
    # So something in my lighting code is broken... maybe some interplay between area lights and alpha masks and shadow rays?
    # thanks claude for generating blender code for me :)
    # https://claude.ai/chat/568340db-6a11-496c-a205-99bc0fbdd481
    ceiling_transform = Translate(Pnt3(0,0,0)) 
    ceiling = parse_obj(
        jmfp("/Users/johnmyslinski/Documents/PBRJ/ref/scene_1_ceiling.obj"),
        ceiling_transform,
        false,
        false,
        nothing
    )
    for tris in ceiling
        for tri in tris
            push!(primitives, Primitive(tri, "mat_white", nothing))
        end
    end    

    ################# RIGHT WALL
    RWALL_S = -foyer_dim/2 + sqrt(hallway_corner_offset^2/2) # ~ -131

    RWALL_S1 = RWALL_S
    RWALL_E1 = RWALL_S + stairs_offset
    
    RWALL_S2 = RWALL_S + stairs_offset + stairs_total_width
    RWALL_E2 = foyer_dim/2 # ~ 300

    @assert RWALL_E1 > RWALL_S1
    @assert RWALL_E2 > RWALL_S2

    rwall_transform = Translate(Pnt3(0,0,0))
    rwall = Rectangle(
        Pnt2(RWALL_S1, 0), 
        Pnt2(RWALL_E1, ceiling_height), 
        -foyer_dim/2,
        3, 
        ShapeCore(rwall_transform, Inv(rwall_transform), false, false),
        false,
        nothing
    )
    for tri in rwall
        push!(primitives, Primitive(tri, "mat_white", nothing))
    end

    rwall_transform = Translate(Pnt3(0,0,0))
    rwall = Rectangle(
        Pnt2(RWALL_S2, 0), 
        Pnt2(RWALL_E2, ceiling_height), 
        -foyer_dim/2,
        3, 
        ShapeCore(rwall_transform, Inv(rwall_transform), false, false),
        false,
        nothing
    )
    for tri in rwall
        push!(primitives, Primitive(tri, "mat_white", nothing))
    end

    ################# STAIRS

    # a dummy light to illuminate new work
    stair_light_t = Translate(Pnt3(
        (RWALL_E1 + RWALL_S2) / 2,
        ceiling_height * 2,
        -foyer_dim/2 - stairs_depth/2
    ))
    stair_light = Sphere(
        ShapeCore(
            stair_light_t,
            Inv(stair_light_t),
            false,
            false
        ),  
        25.0
    )
    stair_light_alight = DiffuseAreaLight(
        spectrum_from_float(1.0, 1.0, 1.0),
        stair_light,
        false
    )
    push!(lights, stair_light_alight)
    push!(lights2, stair_light_alight)
    push!(primitives, Primitive(stair_light, "mat_white", stair_light_alight))
    push!(primitives2, Primitive(stair_light, "mat_white", stair_light_alight))

    stairs = create_stair_rectangles(
        Pnt3(
            RWALL_E1,
            0.0,
            -foyer_dim/2
        ),
        Pnt3(
            RWALL_S2,
            ceiling_height/2,
            -foyer_dim/2 - stairs_depth
        ),
        6,
        3,
        ShapeCore(),
        false,
        nothing
    )
    for tris in stairs
        for tri in tris
            push!(primitives, Primitive(tri, "mat_concrete", nothing))
            push!(primitives2, Primitive(tri, "mat_concrete", nothing))
        end
    end

    stairs_landing_t = Translate(Pnt3(0,0,0))
    stairs_landing = Rectangle(
        Pnt2(
            RWALL_S2,
            -foyer_dim/2 - stairs_depth * 2
        ),
        Pnt2(
            RWALL_S2 - stairs_total_width * 2,
            -foyer_dim/2 - stairs_depth
        ),
        ceiling_height/2,
        2,
        ShapeCore(stairs_landing_t, Inv(stairs_landing_t), false, false),
        false,
        nothing
    )
    for tri in stairs_landing
        push!(primitives, Primitive(tri, "mat_concrete", nothing))
        push!(primitives2, Primitive(tri, "mat_concrete", nothing))
    end

    stairs_left_wall_t = Translate(Pnt3(0,0,0))
    stairs_left_wall = Rectangle(
        Pnt2(0.0, -foyer_dim/2),
        Pnt2(ceiling_height * 2, -foyer_dim/2 - stairs_depth * 2),
        RWALL_S2,
        1,
        ShapeCore(stairs_left_wall_t, Inv(stairs_left_wall_t), false, false),
        false,
        nothing
    )
    for tri in stairs_left_wall
        push!(primitives, Primitive(tri, "mat_white", nothing))
        push!(primitives2, Primitive(tri, "mat_white", nothing))
    end

    stairs_right_wall_t = Translate(Pnt3(0,0,0))
    stairs_right_wall = Rectangle(
        Pnt2(0.0, -foyer_dim/2),
        Pnt2(ceiling_height * 2, -foyer_dim/2 - stairs_depth),
        RWALL_E1,
        1,
        ShapeCore(stairs_right_wall_t, Inv(stairs_right_wall_t), false, false),
        false,
        nothing
    )
    for tri in stairs_right_wall
        push!(primitives, Primitive(tri, "mat_white", nothing))
        push!(primitives2, Primitive(tri, "mat_white", nothing))
    end

    stairs_back_wall_t = Translate(Pnt3(0, 0, 0))
    stairs_back_wall = Rectangle(
        Pnt2(RWALL_S2, 0.0),
        Pnt2(RWALL_S2 - stairs_total_width * 2, ceiling_height*2),
        -foyer_dim/2 - stairs_depth * 2,
        3,
        ShapeCore(stairs_back_wall_t, Inv(stairs_back_wall_t), false, false),
        false,
        nothing
    )
    for tri in stairs_back_wall
        push!(primitives, Primitive(tri, "mat_white", nothing))
        push!(primitives2, Primitive(tri, "mat_white", nothing))
    end

    ################# LEFT WALL
    LWALL_S = -foyer_dim/2 + sqrt(hallway_corner_offset^2/2) # ~ -131

    LWALL_S1 = LWALL_S
    LWALL_E1 = LWALL_S + elevator_offset
    
    LWALL_S2 = LWALL_S + elevator_offset + elevator_total_width
    LWALL_E2 = foyer_dim/2 # ~ 300

    @assert LWALL_E1 > LWALL_S1
    @assert LWALL_E2 > LWALL_S2

    lwall_transform = Translate(Pnt3(0,0,0))
    lwall = Rectangle(
        Pnt2(0, LWALL_S1), 
        Pnt2(ceiling_height, LWALL_E1), 
        -foyer_dim/2,
        1, 
        ShapeCore(lwall_transform, Inv(lwall_transform), false, false),
        false,
        nothing
    )
    for tri in lwall
        push!(primitives, Primitive(tri, "mat_white", nothing))
    end

    lwall_transform = Translate(Pnt3(0,0,0))
    lwall = Rectangle(
        Pnt2(0.0, LWALL_S2), 
        Pnt2(ceiling_height, LWALL_E2), 
        -foyer_dim/2,
        1, 
        ShapeCore(lwall_transform, Inv(lwall_transform), false, false),
        false,
        nothing
    )
    for tri in lwall
        push!(primitives, Primitive(tri, "mat_white", nothing))
    end

    ################# Elevator

    elevator_door1_t = Translate(Pnt3(0,0,0))
    elevator_door1 = Rectangle(
        Pnt2(0.0, LWALL_E1), 
        Pnt2(ceiling_height, LWALL_E1 + elevator_total_width/2 - elevator_door_gap / 2), 
        -foyer_dim/2,
        1, 
        ShapeCore(elevator_door1_t, Inv(elevator_door1_t), false, false),
        false,
        nothing
    )
    for tri in elevator_door1
        push!(primitives, Primitive(tri, "mat_metal_door", nothing))
    end

    elevator_door2_t = Translate(Pnt3(0,0,0))
    elevator_door2 = Rectangle(
        Pnt2(0.0, LWALL_E1 + elevator_total_width/2 + elevator_door_gap / 2), 
        Pnt2(ceiling_height, LWALL_S2), 
        -foyer_dim/2,
        1, 
        ShapeCore(elevator_door2_t, Inv(elevator_door2_t), false, false),
        false,
        nothing
    )
    for tri in elevator_door2
        push!(primitives, Primitive(tri, "mat_metal_door", nothing))
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
        push!(primitives2, Primitive(tri, "mat_white", nothing))
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
        push!(primitives2, Primitive(tri, "mat_white", nothing))
    end

    ################# Front Pillar Edges
    pillar_front_right_t = Translate(Pnt3(0,0,0))
    pillar_front_right = Box(
        Pnt3(
            -pillar_width_2,
            0,
            pillar_width_1
        ), 
        Pnt3(
            -pillar_width_2 + pillar_edge_thickness,  
            ceiling_circle_height, 
            pillar_width_1 + pillar_edge_thickness
        ), 
        ShapeCore(pillar_front_right_t, Inv(pillar_front_right_t), false, false),
        nothing
    )
    for tri in pillar_front_right
        push!(primitives, Primitive(tri, "mat_white", nothing))
        push!(primitives2, Primitive(tri, "mat_white", nothing))
    end

    pillar_front_left_t = Translate(Pnt3(0,0,0))
    pillar_front_left = Box(
        Pnt3(
            pillar_width_2 - pillar_edge_thickness,
            0,
            pillar_width_1
        ), 
        Pnt3(
            pillar_width_2,  
            ceiling_circle_height, 
            pillar_width_1 + pillar_edge_thickness
        ), 
        ShapeCore(pillar_front_left_t, Inv(pillar_front_left_t), false, false),
        nothing
    )
    for tri in pillar_front_left
        push!(primitives, Primitive(tri, "mat_white", nothing))
        push!(primitives2, Primitive(tri, "mat_white", nothing))
    end

    pillar_front_horizonal_t = Translate(Pnt3(0, 0, 0))
    heights = Int64[0, 55, 110, 165, 210]
    for height in heights
        pillar_front_horizontal = Box(
            Pnt3(
                -pillar_width_2 + pillar_edge_thickness,
                height,
                pillar_width_1
            ),
            Pnt3(
                pillar_width_2 - pillar_edge_thickness,
                height + 5,
                pillar_width_1 + pillar_edge_thickness
            ),
            ShapeCore(pillar_front_horizonal_t, Inv(pillar_front_horizonal_t), false, false),
            nothing
        )
        for tri in pillar_front_horizontal
            push!(primitives, Primitive(tri, "mat_white", nothing))
            push!(primitives2, Primitive(tri, "mat_white", nothing))
        end
    end

    ################# Right Pillar Edges
    pillar_right_right_t = Translate(Pnt3(0,0,0))
    pillar_right_right = Box(
        Pnt3(
            -pillar_width_1-pillar_edge_thickness,
            0,
            -pillar_width_2
        ), 
        Pnt3(
            -pillar_width_1,  
            ceiling_circle_height, 
            -pillar_width_2 + pillar_edge_thickness
        ), 
        ShapeCore(pillar_right_right_t, Inv(pillar_right_right_t), false, false),
        nothing
    )
    for tri in pillar_right_right
        push!(primitives, Primitive(tri, "mat_white", nothing))
        push!(primitives2, Primitive(tri, "mat_white", nothing))
    end

    pillar_right_left_t = Translate(Pnt3(0,0,0))
    pillar_right_left = Box(
        Pnt3(
            -pillar_width_1 - pillar_edge_thickness,
            0,
            pillar_width_2 - pillar_edge_thickness
        ), 
        Pnt3(
            -pillar_width_1,  
            ceiling_circle_height, 
            pillar_width_2
        ), 
        ShapeCore(pillar_right_left_t, Inv(pillar_right_left_t), false, false),
        nothing
    )
    for tri in pillar_right_left
        push!(primitives, Primitive(tri, "mat_white", nothing))
        push!(primitives2, Primitive(tri, "mat_white", nothing))
    end

    pillar_right_horizonal_t = Translate(Pnt3(0, 0, 0))
    heights = Int64[0, 55, 110, 165, 210]
    for height in heights
        pillar_right_horizontal = Box(
            Pnt3(
                -pillar_width_1 - pillar_edge_thickness,
                height,
                -pillar_width_2 + pillar_edge_thickness
            ),
            Pnt3(
                -pillar_width_1,
                height + 5,
                pillar_width_2 - pillar_edge_thickness
            ),
            ShapeCore(pillar_right_horizonal_t, Inv(pillar_right_horizonal_t), false, false),
            nothing
        )
        for tri in pillar_right_horizontal
            push!(primitives, Primitive(tri, "mat_white", nothing))
            push!(primitives2, Primitive(tri, "mat_white", nothing))
        end
    end

    ################# Left Pillar Edges
    pillar_left_right_t = Translate(Pnt3(0,0,0))
    pillar_left_right = Box(
        Pnt3(
            pillar_width_1,
            0,
            -pillar_width_2
        ), 
        Pnt3(
            pillar_width_1 + pillar_edge_thickness,  
            ceiling_circle_height, 
            -pillar_width_2 + pillar_edge_thickness
        ), 
        ShapeCore(pillar_left_right_t, Inv(pillar_left_right_t), false, false),
        nothing
    )
    for tri in pillar_left_right
        push!(primitives, Primitive(tri, "mat_white", nothing))
        push!(primitives2, Primitive(tri, "mat_white", nothing))
    end

    pillar_left_left_t = Translate(Pnt3(0,0,0))
    pillar_left_left = Box(
        Pnt3(
            pillar_width_1,
            0,
            pillar_width_2 - pillar_edge_thickness
        ), 
        Pnt3(
            pillar_width_1 + pillar_edge_thickness,  
            ceiling_circle_height, 
            pillar_width_2
        ), 
        ShapeCore(pillar_left_left_t, Inv(pillar_left_left_t), false, false),
        nothing
    )
    for tri in pillar_left_left
        push!(primitives, Primitive(tri, "mat_white", nothing))
        push!(primitives2, Primitive(tri, "mat_white", nothing))
    end

    pillar_left_horizonal_t = Translate(Pnt3(0, 0, 0))
    heights = Int64[0, 55, 110, 165, 210]
    for height in heights
        pillar_left_horizontal = Box(
            Pnt3(
                pillar_width_1,
                height,
                -pillar_width_2 + pillar_edge_thickness
            ),
            Pnt3(
                pillar_width_1 + pillar_edge_thickness,
                height + 5,
                pillar_width_2 - pillar_edge_thickness
            ),
            ShapeCore(pillar_left_horizonal_t, Inv(pillar_left_horizonal_t), false, false),
            nothing
        )
        for tri in pillar_left_horizontal
            push!(primitives, Primitive(tri, "mat_white", nothing))
            push!(primitives2, Primitive(tri, "mat_white", nothing))
        end
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
    MULT_albedo = 8.0
    MULT_light = 8.0
    yellow = spectrum_from_float(1.0, 1.0, 0.0)
    white = spectrum_from_float(1.0, 1.0, 1.0)
    blue = spectrum_from_float(0.0, 0.0, 1.0)
    red = spectrum_from_float(1.0, 0.0, 0.0)
    pink = spectrum_from_float(1.0, 0.0, 1.0)
    green = spectrum_from_float(0.0, 1.0, 0.0)
    pillar_area_light_spec = Tuple{Pnt2, Pnt2, Float64, Int64, Spectrum, String, Bool}[
        (Pnt2(5,    -pillar_width_2+pillar_edge_thickness), Pnt2(55,   pillar_width_2-pillar_edge_thickness), pillar_width_1+.5, 1, yellow, "yellow", false),
        (Pnt2(60,   -pillar_width_2+pillar_edge_thickness), Pnt2(110,  pillar_width_2-pillar_edge_thickness), pillar_width_1+.5, 1, white, "white", false),
        (Pnt2(115,  -pillar_width_2+pillar_edge_thickness), Pnt2(165,  pillar_width_2-pillar_edge_thickness), pillar_width_1+.5, 1, pink, "pink", false),
        (Pnt2(170,  -pillar_width_2+pillar_edge_thickness), Pnt2(210,  pillar_width_2-pillar_edge_thickness), pillar_width_1+.5, 1, blue, "blue", false),
        (Pnt2(215,  -pillar_width_2+pillar_edge_thickness), Pnt2(265,  pillar_width_2-pillar_edge_thickness), pillar_width_1+.5, 1, red, "red", false),

        (Pnt2(-pillar_width_2+pillar_edge_thickness, 5),   Pnt2(pillar_width_2-pillar_edge_thickness, 55),  pillar_width_1+.5, 3, white, "white", false),
        (Pnt2(-pillar_width_2+pillar_edge_thickness, 60),  Pnt2(pillar_width_2-pillar_edge_thickness, 110), pillar_width_1+.5, 3, blue, "blue", false),
        (Pnt2(-pillar_width_2+pillar_edge_thickness, 115), Pnt2(pillar_width_2-pillar_edge_thickness, 165), pillar_width_1+.5, 3, red, "red", false),
        (Pnt2(-pillar_width_2+pillar_edge_thickness, 170), Pnt2(pillar_width_2-pillar_edge_thickness, 210), pillar_width_1+.5, 3, pink, "pink", false),
        (Pnt2(-pillar_width_2+pillar_edge_thickness, 215), Pnt2(pillar_width_2-pillar_edge_thickness, 265), pillar_width_1+.5, 3, green, "green", false),

        (Pnt2(5,    -pillar_width_2+pillar_edge_thickness), Pnt2(55,   pillar_width_2-pillar_edge_thickness), -pillar_width_1-.5, 1, yellow, "yellow", true),
        (Pnt2(60,   -pillar_width_2+pillar_edge_thickness), Pnt2(110,  pillar_width_2-5pillar_edge_thickness), -pillar_width_1-.5, 1, white, "white", true),
        (Pnt2(115,  -pillar_width_2+pillar_edge_thickness), Pnt2(165,  pillar_width_2-pillar_edge_thickness), -pillar_width_1-.5, 1, pink, "pink", true),
        (Pnt2(170,  -pillar_width_2+pillar_edge_thickness), Pnt2(210,  pillar_width_2-pillar_edge_thickness), -pillar_width_1-.5, 1, blue, "blue", true),
        (Pnt2(215,  -pillar_width_2+pillar_edge_thickness), Pnt2(265,  pillar_width_2-pillar_edge_thickness), -pillar_width_1-.5, 1, red, "red", true),

        (Pnt2(-pillar_width_2+pillar_edge_thickness, 5),   Pnt2(pillar_width_2-pillar_edge_thickness, 55),  -pillar_width_1-.5, 3, white, "white", true),
        (Pnt2(-pillar_width_2+pillar_edge_thickness, 60),  Pnt2(pillar_width_2-pillar_edge_thickness, 110), -pillar_width_1-.5, 3, blue, "blue", true),
        (Pnt2(-pillar_width_2+pillar_edge_thickness, 115), Pnt2(pillar_width_2-pillar_edge_thickness, 165), -pillar_width_1-.5, 3, red, "red", true),
        (Pnt2(-pillar_width_2+pillar_edge_thickness, 170), Pnt2(pillar_width_2-pillar_edge_thickness, 210), -pillar_width_1-.5, 3, pink, "pink", true),
        (Pnt2(-pillar_width_2+pillar_edge_thickness, 215), Pnt2(pillar_width_2-pillar_edge_thickness, 265), -pillar_width_1-.5, 3, green, "green", true),
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
        mat_parchment = Matte(
            "mat_parchment_" * mat_name,
            MixMultTexture(
                ImageTexture(
                    UVMapping2D(),
                    jmfp("/Users/johnmyslinski/Documents/PBRJ/ref/parchment/parchment_1.jpg"),
                    false
                ),
                ConstantTexture(brightness * MULT_albedo)
            ),
            ConstantTexture(0.0),
            nothing
        )
        push!(materials, mat_parchment)

        for tri in tmp_rec
            alight = DiffuseAreaLight(
                brightness * MULT_light,
                tri,
                false
            )
            push!(primitives, Primitive(tri, "mat_parchment_" * mat_name, nothing))
            push!(primitives2, Primitive(tri, "mat_parchment_" * mat_name, nothing))
            push!(lights, alight)
            push!(lights2, alight)
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

    l_2_w = Translate(Pnt3(0,0,0))
    light = UniformInfiniteLight(
        world_bounds(bvh), 
        l_2_w, 
        Spectrum(0.1, 0.1, 0.1), 
    )
    push!(lights, light)
    push!(lights2, light)

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
    # look_from = Pnt3(150, 200, 400)
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
    # I = BDPTIntegrator(C, S, parsed_args["max-depth"])
    # I = AOIntegrator(C, S, true)
    I = SimpleIntegrator(C, S)

    return I, scene
end
function make_scene113(parsed_args::Dict)::Tuple{AbstractIntegrator, Scene}
    primitives = Primitive[]
    lights = Light[]
    materials = Material[]

    mat_light = Matte(
        "mat_light",
        ConstantTexture(spectrum_from_float(1.0, 0.8466667, 0.8)),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_light)

    mat_coated_diffuse_1 = Uber(
        "mat_coated_diffuse_1",
        ConstantTexture(spectrum_from_float(1.0, 1.0, 1.0)),
        ImageTexture(
            UVMapping2D(),
            jmfp("/Users/johnmyslinski/Documents/pbrt-v4-volumes/scenes/matchbulb/tex/plane_BaseColor.exr"),
            false
        ),
        ConstantTexture(spectrum_from_float(0.0)),
        ConstantTexture(spectrum_from_float(0.0)),
        ImageTexture(
            UVMapping2D(),
            jmfp("/Users/johnmyslinski/Documents/pbrt-v4-volumes/scenes/matchbulb/tex/plane_Roughness.exr"),
            true
        ),
        nothing, nothing,
        ConstantTexture(1.5),
        ConstantTexture(spectrum_from_float(1.0)),
        nothing,
        false
    )
    push!(materials, mat_coated_diffuse_1)


    mat_aluminum_rough = Metal(
        "mat_aluminum_rough",
        ConstantTexture(spectrum_from_sampled(jmfp("/home/jmyslinski/random_stuff/pbrt-v3-scenes/bathroom/spds/Ag.eta.spd"))),
        ConstantTexture(spectrum_from_sampled(jmfp("/home/jmyslinski/random_stuff/pbrt-v3-scenes/bathroom/spds/Ag.k.spd"))),
        MixMultTexture(
            ConstantTexture(0.3),
            ImageTexture(
                UVMapping2D(),
                jmfp("/Users/johnmyslinski/Documents/pbrt-v4-volumes/scenes/matchbulb/tex/bulb_cap_Roughness.exr"),
                true
            )
        ),
        nothing, nothing,
        nothing,
        false
    )
    push!(materials, mat_aluminum_rough)

    mat_glass = Glass(
        "mat_glass"
    )
    push!(materials, mat_glass)

    mat_ceramic = Matte(
        "mat_ceramic",
        ConstantTexture(spectrum_from_float(0.75, 0.75, 0.75)),
        ConstantTexture(0.2),
        nothing
    )
    push!(materials, mat_ceramic)

    mat_aluminum = Metal(
        "mat_aluminum",
        ConstantTexture(spectrum_from_sampled(jmfp("/home/jmyslinski/random_stuff/pbrt-v3-scenes/bathroom/spds/Ag.eta.spd"))),
        ConstantTexture(spectrum_from_sampled(jmfp("/home/jmyslinski/random_stuff/pbrt-v3-scenes/bathroom/spds/Ag.k.spd"))),
        ConstantTexture(0.05),
        nothing, nothing,
        nothing,
        true
    )
    push!(materials, mat_aluminum)

    mat_matchstick_color = Matte(
        "mat_matchstick_color",
        ImageTexture(
            UVMapping2D(),
            jmfp("/Users/johnmyslinski/Documents/pbrt-v4-volumes/scenes/matchbulb/tex/plane_BaseColor.exr"),
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_matchstick_color)

    # key light
    key_light_t = Translate(Pnt3(-7.3736606, 6.133034, -4.33098)) *
        Rotate(1.2462447,  Vec3(0, 0, 1)) * 
        Rotate(-120.24111, Vec3(0, 1, 0)) *  
        Rotate(-19.609451, Vec3(1, 0, 0)) *  
        Scale(2.0, 4.0, 2.0)
    patches = BilinearPatchGenerator(
        ShapeCore(key_light_t, Inv(key_light_t), false, false),
        1,
        Pnt3[Pnt3(-0.5, -0.5, 0), Pnt3(0.5, -0.5, 0), Pnt3(-0.5, 0.5, 0), Pnt3(0.5, 0.5, 0)],
        Int64[1, 2, 3, 4],
        nothing, nothing,
        nothing, nothing,
        nothing
    )
    for patch in patches
        patch_light = DiffuseAreaLight(
            spectrum_from_float(5.656854, 5.656854, 5.656854),
            patch,
            false
        )
        push!(lights, patch_light)
        push!(primitives, Primitive(patch, "mat_light", patch_light))
    end


    bulb_contact = parse_obj(
        jmfp("/Users/johnmyslinski/Documents/pbrt-v4-volumes/scenes/matchbulb/geometry/bulb_contact_ascii.obj"), 
        Translate(Pnt3(0,0,0)),
        false,
        false,
        nothing
    )
    for tris in bulb_contact
        for tri in tris
            push!(primitives, Primitive(tri, "mat_aluminum", nothing))
        end
    end

    ceramic = parse_obj(
        jmfp("/Users/johnmyslinski/Documents/pbrt-v4-volumes/scenes/matchbulb/geometry/ceramic_ascii.obj"), 
        Translate(Pnt3(0,0,0)),
        false,
        false,
        nothing
    )
    for tris in ceramic
        for tri in tris
            push!(primitives, Primitive(tri, "mat_ceramic", nothing))
        end
    end

    glass_bulb = parse_obj(
        jmfp("/Users/johnmyslinski/Documents/pbrt-v4-volumes/scenes/matchbulb/geometry/glass_bulb_ascii.obj"), 
        Translate(Pnt3(0,0,0)),
        false,
        false,
        nothing
    )
    for tris in glass_bulb
        for tri in tris
            push!(primitives, Primitive(tri, "mat_glass", nothing))
        end
    end

    bulb_cap = parse_obj(
        jmfp("/Users/johnmyslinski/Documents/pbrt-v4-volumes/scenes/matchbulb/geometry/bulb_cap_ascii.obj"), 
        Translate(Pnt3(0,0,0)),
        false,
        false,
        nothing
    )
    for tris in bulb_cap
        for tri in tris
            push!(primitives, Primitive(tri, "mat_aluminum_rough", nothing))
        end
    end

    match = parse_obj(
        jmfp("/Users/johnmyslinski/Documents/pbrt-v4-volumes/scenes/matchbulb/geometry/matchstick_ascii.obj"), 
        Translate(Pnt3(0,0,0)),
        false,
        false,
        nothing
    )
    for tris in bulb_cap
        for tri in tris
            push!(primitives, Primitive(tri, "mat_matchstick_color", nothing))
        end
    end 

    # Additional bulb+match instances (L1, R1, L2, R2, L3)
    instance_matrices = [
        Mat4( 0.76604444, 0.0, -0.64278764, 0.0,  -0.6232521,  0.24466307, -0.7427629,  0.0,   0.1572664,  0.9696082,  0.18742278, 0.0,  -0.5,      0.2452139,  -3.943021,  1.0),  # L1
        Mat4(-0.5,        0.0,  0.8660254,  0.0,   0.8397053,  0.24466307,  0.4848041,  0.0,  -0.21188444, 0.9696082, -0.12233154, 0.0,   0.50736,   0.2452139,  -3.636737,  1.0),  # R1
        Mat4(-0.7858569,  0.0,  0.6184084,  0.0,   0.59961385, 0.24466307,  0.76197326, 0.0,  -0.1513017,  0.9696082, -0.19227016, 0.0,  -2.59264,   0.2452139,  -1.83674,   1.0),  # L2
        Mat4( 0.49044752, 0.0,  0.87147075, 0.0,   0.8449851,  0.24466307, -0.47554192, 0.0,  -0.2132167,  0.9696082,  0.119994394,0.0,   1.09596,   0.2452139,   1.87731,   1.0),  # R2
        Mat4( 0.98768836, 0.0, -0.15643446, 0.0,  -0.15168013, 0.24466307, -0.9576707,  0.0,   0.038273737,0.9696082,  0.24165086, 0.0,  -6.69,      0.2452139, -11.44302,   1.0),  # L3
    ]
    bulb_geo = [
        (jmfp("/Users/johnmyslinski/Documents/pbrt-v4-volumes/scenes/matchbulb/geometry/bulb_contact_ascii.obj"), "mat_aluminum"),
        (jmfp("/Users/johnmyslinski/Documents/pbrt-v4-volumes/scenes/matchbulb/geometry/ceramic_ascii.obj"),      "mat_ceramic"),
        (jmfp("/Users/johnmyslinski/Documents/pbrt-v4-volumes/scenes/matchbulb/geometry/glass_bulb_ascii.obj"),   "mat_glass"),
        (jmfp("/Users/johnmyslinski/Documents/pbrt-v4-volumes/scenes/matchbulb/geometry/bulb_cap_ascii.obj"),     "mat_aluminum_rough"),
    ]
    for m in instance_matrices
        inst_t = Transformation(m, inv(m))
        for (path, matname) in bulb_geo
            for tris in parse_obj(path, inst_t, false, false, nothing)
                for tri in tris
                    push!(primitives, Primitive(tri, matname, nothing))
                end
            end
        end
        for tris in parse_obj(jmfp("/Users/johnmyslinski/Documents/pbrt-v4-volumes/scenes/matchbulb/geometry/matchstick_ascii.obj"), inst_t, false, false, nothing)
            for tri in tris
                push!(primitives, Primitive(tri, "mat_matchstick_color", nothing))
            end
        end
    end

    ground_t = Transformation(Mat4(5, 0, 0, 0, 0, 5, 0, 0, 0, 0, 5, 0, 0, 0, 0, 1))
    ground = parse_obj(
        jmfp("/Users/johnmyslinski/Documents/pbrt-v4-volumes/scenes/matchbulb/geometry/ground_ascii.obj"), 
        ground_t,
        false,
        false,
        nothing
    )
    for tris in ground
        for tri in tris
            push!(primitives, Primitive(tri, "mat_coated_diffuse_1", nothing))
        end
    end 

    name_index = Dict(mat.name => i for (i, mat) in enumerate(materials))
    MATERIAL_REGISTRY[] = MaterialRegistry(materials, name_index)

    # instantiate accelerator
    print("\nThere are " * num2str(length(primitives)) * " objects in the scene, building BVH\n")
    @time bvh = BVH(primitives)
    print("Done building BVH\n")

    l_2_w_matrix = Mat4([-0.224951, 0.0, -0.97437, 0.0, -0.97437, 0.0, 0.224951, 0.0, 0.0, 1.0, 0.0, 8.87, 0.0, 0.0, 0.0, 1.0])
    l_2_w = Transformation(l_2_w_matrix, inv(l_2_w_matrix))
    light = InfiniteLight(
        world_bounds(bvh),
        l_2_w,
        spectrum_from_float(1.0),
        jmfp("/Users/johnmyslinski/Documents/pbrt-v3-scenes/sssdragon/textures/envmap.exr"),
        false
    )
    push!(lights, light)

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
    # camera_t = LookAt(
    #     Pnt3(0, -1.1793004, 6.285956), 
    #     Pnt3(0, 0, 0), 
    #     Vec3(0, 1, 0)
    # )
    camera_t = Transformation(Mat4(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, -1, 0, 0, -1.1793004, 6.285956, 1))
    screen = Bounds2(Pnt2(-1, -0.5625), Pnt2(1, 0.5625))
    C = PerspectiveCamera(camera_t, screen, 0.0, 1.0, 0.0, 1e6, 45.0, film)

    # Instantiate a Sampler
    S = SamplerFactory(parsed_args)
    print("Using " * num2str(S.samples_per_pixel) * " samples per pixel\n")
    
    # Instantiate Scene
    print("There are " * num2str(length(lights)) * " lights in the scene\n")
    scene = Scene(lights, bvh)
    
    # Instantiate an Integrator
    I = VolPathIntegratorv3(C, S, parsed_args["max-depth"])

    return I, scene
end

function make_scene14(parsed_args::Dict)::Tuple{AbstractIntegrator, Scene}
    primitives = Primitive[]
    lights = Light[]
    materials = Material[]

    mat_stand = Metal(
        "mat_stand",
        ConstantTexture(spectrum_from_sampled(jmfp("/home/jmyslinski/random_stuff/pbrt-v3-scenes/bathroom/spds/Ag.eta.spd"))),
        ConstantTexture(spectrum_from_sampled(jmfp("/home/jmyslinski/random_stuff/pbrt-v3-scenes/bathroom/spds/Ag.k.spd"))),
        ConstantTexture(0.001),
    )
    push!(materials, mat_stand)

    mat_ground = Matte(
        "mat_ground",
        ConstantTexture(spectrum_from_float(0.2, 0.2, 0.2)),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_ground)

    # materials
    dir_mix_texture = MixDirectionTexture(
        ConstantTexture(.0005),
        ConstantTexture(.005),
        Vec3(0, 9, 24)
    )

    mat_glass = Glass(
        "mat_glass",
        ConstantTexture(spectrum_from_float(1.0)), # Kr
        ConstantTexture(spectrum_from_float(1.0)), # Kt
        dir_mix_texture,  # u_roughness
        dir_mix_texture,  # v_roughness
        ConstantTexture(1.5), # eta
        nothing,                    # bump
        true                        # remap_roughness
    )
    push!(materials, mat_glass)

    name_index = Dict(mat.name => i for (i, mat) in enumerate(materials))
    MATERIAL_REGISTRY[] = MaterialRegistry(materials, name_index)

    # Instantiate a Filter
    filter = GaussianFilter(Pnt2(2, 2))

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
    # camera_t = Translate(Pnt3(0, 15, 0)) * Transformation(Mat4(1, 0, 0, 0, 0, 0.978148, -0.207912, 0, 0, -0.207912, -0.978148, 0, 0, -3.81345, 25.3467, 1)) 
    camera_t = LookAt(Pnt3(0,9,24), Pnt3(0,4,0), Vec3(0,1,0)) * Scale(-1.0, 1.0, 1.0)
    screen = Bounds2(Pnt2(-1, -0.5625), Pnt2(1, 0.5625))
    C = PerspectiveCamera(camera_t, screen, 0.0, 1.0, 0.0, 1e6, 45.0, film)

    # this matches PBRT. wtf is that base transformation baked in there...
    #     media_t = RayTracing.Transformation(RayTracing.Mat4( 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0 , -8.999994 , -23.999943, 1 )) *
    # RayTracing.Transformation(RayTracing.Mat4(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 4.705, 0, 1)) * 
    # RayTracing.Transformation(RayTracing.Mat4(3.18, 0, 0, 0, 0, 3.212, 0, 0, 0, 0, 3.1, 0, 0.008, -0.024, -0.064, 1)) 

    # Bounding sphere cause we hate winding order and such
    media_t = Transformation(Mat4(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 4.705, 0, 1)) *
        Transformation(Mat4(3.18, 0, 0, 0, 0, 3.212, 0, 0, 0, 0, 3.1, 0, 0.008, -0.024, -0.064, 1))

    println("Parsing Medium... hold tight")
    anemone_mi = MediumInterface(
        GridMedium(
            jmfp("/Users/johnmyslinski/Documents/pbrt-v4-volumes/scenes/anemone/geometry/anemone_medium.pbrt"),
            media_t,
            spectrum_from_float(0.1, 0.9, 0.5),
            spectrum_from_float(0.2, .01, 1.0),
            1.0,
            spectrum_from_float(10.0, 0.5, 5.0),
            1.0, # TODO HACK BECAUSE I DONT HAVE PHOTO NORMALIZATION
            0.0,
            Pnt3i(256, 256, 256)
        ),
        nothing
    )
    println("Done Parsing Medium... let loose")

    ground_t = Transformation(Mat4(10, 0, 0, 0, 0, 10, 0, 0, 0, 0, 10, 0, 0, 0, 0, 1)) * 
        Transformation(Mat4(500, 0, 0, 0, 0, 0, -500, 0, 0, 1, 0, 0, 0, 0, 0, 1))
    ground = Disk(
        ground_t, 
        1.0, 
        false, 
        false
    )
    push!(primitives, Primitive(ground, "mat_ground", nothing))

    orb_t1 = Transformation(Mat4(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 4.705, 0, 1)) *
        Transformation(Mat4(3.52, 0, 0, 0, 0, 0, -3.52, 0, 0, 3.52, 0, 0, 0, 0, 0, 1))

    orb_media = Sphere(
        ShapeCore(orb_t1, Inv(orb_t1), false, false),
        1.0
    )
    push!(primitives, Primitive(orb_media, nothing, nothing, anemone_mi))

    orb_t2 = Transformation(Mat4(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 4.705, 0, 1)) *
    Transformation(Mat4(3.696, 0, 0, 0, 0, 0, -3.696, 0, 0, 3.696, 0, 0, 0, 0, 0, 1))

    orb_glass = Sphere(
        ShapeCore(orb_t2, Inv(orb_t2), false, false),
        1.0
    )
    push!(primitives, Primitive(orb_glass, "mat_glass", nothing))

    stand_orb1_t = Transformation(Mat4(3.7, 0, 0, 0, 0, 3.7, 0, 0, 0, 0, 3.7, 0, 0, 0, 0, 1)) * 
        Transformation(Mat4(0.04, 0, 0, 0, 0, 0, -0.04, 0, 0, 0.04, 0, 0, 0.879841, 0.70134, 0, 1))
    stand_orb1 = Sphere(
        ShapeCore(stand_orb1_t, Inv(stand_orb1_t), false, false),
        1.0
    )
    push!(primitives, Primitive(stand_orb1, "mat_stand", nothing))

    stand_orb2_t = Transformation(Mat4(3.7, 0, 0, 0, 0, 3.7, 0, 0, 0, 0, 3.7, 0, 0, 0, 0, 1)) * 
        Transformation(Mat4(0.04, 0, 0, 0, 0, 0, -0.04, 0, 0, 0.04, 0, 0, 0.993051, 0.04, 0, 1))
    stand_orb2 = Sphere(
        ShapeCore(stand_orb2_t, Inv(stand_orb2_t), false, false),
        1.0
    )
    push!(primitives, Primitive(stand_orb2, "mat_stand", nothing))

    stand_orb3_t = Transformation(Mat4(3.7, 0, 0, 0, 0, 3.7, 0, 0, 0, 0, 3.7, 0, 0, 0, 0, 1)) * 
        Transformation(Mat4(0.02, 0, -0.034641, 0, -0.034641, 0, -0.02, 0, 0, 0.04, 0, 0, 0.439921, 0.70134, -0.761965, 1))
    stand_orb3 = Sphere(
        ShapeCore(stand_orb3_t, Inv(stand_orb3_t), false, false),
        1.0
    )
    push!(primitives, Primitive(stand_orb3, "mat_stand", nothing))

    stand_orb4_t = Transformation(Mat4(3.7, 0, 0, 0, 0, 3.7, 0, 0, 0, 0, 3.7, 0, 0, 0, 0, 1)) * 
        Transformation(Mat4(0.02, 0, -0.034641, 0, -0.034641, 0, -0.02, 0, 0, 0.04, 0, 0, 0.496525, 0.04, -0.860007, 1))
    stand_orb4 = Sphere(
        ShapeCore(stand_orb4_t, Inv(stand_orb4_t), false, false),
        1.0
    )
    push!(primitives, Primitive(stand_orb4, "mat_stand", nothing))

    stand_orb5_t = Transformation(Mat4(3.7, 0, 0, 0, 0, 3.7, 0, 0, 0, 0, 3.7, 0, 0, 0, 0, 1)) * 
        Transformation(Mat4(-0.02, 0, -0.034641, 0, -0.034641, 0, 0.02, 0, 0, 0.04, 0, 0, -0.439921, 0.70134, -0.761965, 1))
    stand_orb5 = Sphere(
        ShapeCore(stand_orb5_t, Inv(stand_orb5_t), false, false),
        1.0
    )
    push!(primitives, Primitive(stand_orb5, "mat_stand", nothing))

    stand_orb6_t = Transformation(Mat4(3.7, 0, 0, 0, 0, 3.7, 0, 0, 0, 0, 3.7, 0, 0, 0, 0, 1)) * 
        Transformation(Mat4(-0.02, 0, -0.034641, 0, -0.034641, 0, 0.02, 0, 0, 0.04, 0, 0, -0.496525, 0.04, -0.860007, 1))
    stand_orb6 = Sphere(
        ShapeCore(stand_orb6_t, Inv(stand_orb6_t), false, false),
        1.0
    )
    push!(primitives, Primitive(stand_orb6, "mat_stand", nothing))

    stand_orb7_t = Transformation(Mat4(3.7, 0, 0, 0, 0, 3.7, 0, 0, 0, 0, 3.7, 0, 0, 0, 0, 1)) * 
        Transformation(Mat4(-0.04, 0, 0, 0, 0, 0, 0.04, 0, 0, 0.04, 0, 0, -0.879841, 0.70134, 0, 1))
    stand_orb7 = Sphere(
        ShapeCore(stand_orb7_t, Inv(stand_orb7_t), false, false),
        1.0
    )
    push!(primitives, Primitive(stand_orb7, "mat_stand", nothing))

    stand_orb8_t = Transformation(Mat4(3.7, 0, 0, 0, 0, 3.7, 0, 0, 0, 0, 3.7, 0, 0, 0, 0, 1)) * 
        Transformation(Mat4(-0.04, 0, 0, 0, 0, 0, 0.04, 0, 0, 0.04, 0, 0, -0.993051, 0.04, 0, 1))
    stand_orb8 = Sphere(
        ShapeCore(stand_orb8_t, Inv(stand_orb8_t), false, false),
        1.0
    )
    push!(primitives, Primitive(stand_orb8, "mat_stand", nothing))

    stand_orb9_t = Transformation(Mat4(3.7, 0, 0, 0, 0, 3.7, 0, 0, 0, 0, 3.7, 0, 0, 0, 0, 1)) * 
        Transformation(Mat4(-0.02, 0, 0.034641, 0, 0.034641, 0, 0.02, 0, 0, 0.04, 0, 0, -0.439921, 0.70134, 0.761965, 1))
    stand_orb9 = Sphere(
        ShapeCore(stand_orb9_t, Inv(stand_orb9_t), false, false),
        1.0
    )
    push!(primitives, Primitive(stand_orb9, "mat_stand", nothing))

    stand_orb10_t = Transformation(Mat4(3.7, 0, 0, 0, 0, 3.7, 0, 0, 0, 0, 3.7, 0, 0, 0, 0, 1)) * 
        Transformation(Mat4(-0.02, 0, 0.034641, 0, 0.034641, 0, 0.02, 0, 0, 0.04, 0, 0, -0.496525, 0.04, 0.860007, 1))
    stand_orb10 = Sphere(
        ShapeCore(stand_orb10_t, Inv(stand_orb10_t), false, false),
        1.0
    )
    push!(primitives, Primitive(stand_orb10, "mat_stand", nothing))

    stand_orb11_t = Transformation(Mat4(3.7, 0, 0, 0, 0, 3.7, 0, 0, 0, 0, 3.7, 0, 0, 0, 0, 1)) * 
        Transformation(Mat4(0.02, 0, 0.034641, 0, 0.034641, 0, -0.02, 0, 0, 0.04, 0, 0, 0.439921, 0.70134, 0.761965, 1))
    stand_orb11 = Sphere(
        ShapeCore(stand_orb11_t, Inv(stand_orb11_t), false, false),
        1.0
    )
    push!(primitives, Primitive(stand_orb11, "mat_stand", nothing))

    stand_orb12_t = Transformation(Mat4(3.7, 0, 0, 0, 0, 3.7, 0, 0, 0, 0, 3.7, 0, 0, 0, 0, 1)) * 
        Transformation(Mat4(0.02, 0, 0.034641, 0, 0.034641, 0, -0.02, 0, 0, 0.04, 0, 0, 0.496525, 0.04, 0.860007, 1))
    stand_orb12 = Sphere(
        ShapeCore(stand_orb12_t, Inv(stand_orb12_t), false, false),
        1.0
    )
    push!(primitives, Primitive(stand_orb12, "mat_stand", nothing))

    metal_stand_t = Transformation(Mat4(3.7, 0, 0, 0, 0, 3.7, 0, 0, 0, 0, 3.7, 0, 0, 0, 0, 1)) * RotateX(90.0)
    metal_stand = parse_obj(
        jmfp("/home/jmyslinski/random_stuff/PBRJ/ref/metal_stand.obj"),
        metal_stand_t,
        false,
        false,
        nothing
    )
    for tris in metal_stand
        for tri in tris
            push!(primitives, Primitive(tri, "mat_stand", nothing))
        end
    end


    # instantiate accelerator
    print("\nThere are " * num2str(length(primitives)) * " objects in the scene, building BVH\n")
    @time bvh = BVH(primitives)
    print("Done building BVH\n")

    l_2_w = Rotate(110.0, Vec3(0, 1, 0)) * Rotate(-90.0, Vec3(1, 0, 0))
    light = InfiniteLight(
        world_bounds(bvh), 
        l_2_w, 
        spectrum_from_float(0.05, Illuminant), 
        jmfp("/Users/johnmyslinski/Documents/pbrt-v3-scenes/cloud/textures/skylight-morn.exr"),
        false
    )
    push!(lights, light)

    # instantiate the infinite light
    # l_2_w = Translate(Pnt3(0,0,0))
    # light = UniformInfiniteLight(
    #     world_bounds(bvh), 
    #     l_2_w, 
    #     Spectrum(0.53, 0.57, 0.53), 
    # )
    # push!(lights, light)

    # Instantiate a Sampler
    S = ZSobolSampler(
        parsed_args["samples-per-pixel"], 
        Pnt2i(parsed_args["image-dim"][1], parsed_args["image-dim"][2]), 
        Int8(2),
        parsed_args["seed"]
    )
    # S = StratifiedSampler(parsed_args["samples-per-pixel"], parsed_args["jitter"])
    print("Using " * num2str(S.samples_per_pixel) * " samples per pixel\n")
    
    # Instantiate Scene
    print("There are " * num2str(length(lights)) * " lights in the scene\n")
    scene = Scene(lights, bvh)
    
    # Instantiate an Integrator (default: VolPath)
    integrator_arg = parsed_args["integrator"]
    if integrator_arg == "default"
        I = VolPathIntegratorv3(C, S, parsed_args["max-depth"])
    elseif integrator_arg == "bdpt"
        I = BDPTIntegrator(C, S, parsed_args["max-depth"])
    elseif integrator_arg == "volpath"
        I = VolPathIntegratorv3(C, S, parsed_args["max-depth"])
    elseif integrator_arg == "sppm"
        I = SPPMIntegrator(C, S, C.film, parsed_args["max-depth"], parsed_args["n-iterations"], parsed_args["photons-per-iteration"], 1.0)
    else
        error("Unknown integrator: $(integrator_arg)")
    end

    return I, scene
end
function make_scene18(parsed_args::Dict)::Tuple{AbstractIntegrator, Scene}
    primitives = Primitive[]
    lights = Light[]

    # MATERIALS
    mat_gray = Matte(
        ConstantTexture(spectrum_from_float(.4, .4, .4)),
        ConstantTexture(0.0),
        nothing
    )
    mat_blue = Matte(
        ConstantTexture(spectrum_from_float(0.05, 0.05, .9)),
        ConstantTexture(0.0),
        nothing
    )
    mat_red = Matte(
        ConstantTexture(spectrum_from_float(0.9, 0.05, 0.1)),
        ConstantTexture(0.0),
        nothing
    )
    mat_green = Matte(
        ConstantTexture(spectrum_from_float(0.1, 0.92, 0.15)),
        ConstantTexture(0.0),
        nothing
    )

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

    #########################
    ########## SDFTree ##########
    #########################

    ##############
    ### Part 1 ###
    ##############

    # Create two primitive shapes
    sphere = SDFSphere(
        1.0, 
        RayTracing.ShapeCore(
            Translate(Pnt3(0, 1, 0)),
            Inv(Translate(Pnt3(0, 1, 0))),
            false,
            false
        ), 
        RayTracing.Sphere(RayTracing.Pnt3(0,0,0), 1.0 * 1.1)
    )
    box = SDFBox(RayTracing.Pnt3(1.0, 1.0, 1.0), RayTracing.ShapeCore(), RayTracing.Sphere(RayTracing.Pnt3(0,0,0), 3.0 * 1.1))

    # Create a union of the two shapes
    u_t = Translate(Pnt3(5, 0, 0))
    union_shape = SDFUnion(
        0.1, 
        sphere, 
        box, 
        ShapeCore(
            u_t,
            Inv(u_t),
            false,
            false
        )
    )
    # push!(primitives, Primitive(union_shape, mat_red, nothing))

    #############
    ## PART 2 ###
    #############

    torus = SDFTorus(
        Vec2(2.0, 1.0),
        ShapeCore(),
        Sphere(Pnt3(0,0,0), 2.1)
    )
    frame_box = SDFFrameBox(
        Pnt3(2.0, 3.0, 2.0),
        0.1,
        ShapeCore(),
        Sphere(Pnt3(0,0,0), 6.0 * sqrt(2.0))
    )
    union_shape = SDFUnion(0.5, torus, frame_box, ShapeCore())
    # push!(primitives, Primitive(union_shape, mat_blue, nothing))

    #############
    ## PART 3 ###
    #############

    c_t = Translate(Pnt3(0, 0, 5))
    rounded_cone = SDFRoundedCone(
        2.0,
        1.0,
        3.0,
        ShapeCore(c_t, Inv(c_t), false, false),
        Sphere(Pnt3(0, 0, 0), 6.0)
    )
    # push!(primitives, Primitive(rounded_cone, mat_green, nothing))

    #############
    ## PART 3 ###
    #############

    quad = SDFQuad(
        Vec3(25, -3, 25),
        Vec3(25, -3, -25),
        Vec3(-25, -3, 25),
        Vec3(-25, -3, -25),
        ShapeCore(),
        Sphere(Pnt3(0,0,0), 25 * sqrt(2.0))
    )
    push!(primitives, Primitive(quad, mat_gray, nothing))

    #########################
    #########################

    # instantiate accelerator
    print("\nThere are " * num2str(length(primitives)) * " objects in the scene, building BVH\n")
    @time bvh = BVH(primitives)
    print("Done building BVH\n")

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
    look_from = Pnt3(10, 7, 5)
    look_at = Pnt3(0, 0, 0)
    up = Vec3(0, 1, 0)
    screen = Bounds2(Pnt2(-1, -1), Pnt2(1, 1))
    C = PerspectiveCamera(LookAt(look_from, look_at, up), screen, 0.0, 1.0, 0.0, 1e6, 70.0, film)

    # Instantiate a Sampler
    S = StratifiedSampler(parsed_args["samples-per-pixel"], parsed_args["jitter"])
    print("Using " * num2str(S.samples_per_pixel) * " samples per pixel\n")
    
    # Instantiate Scene
    print("There are " * num2str(length(lights)) * " lights in the scene\n")
    scene = Scene(lights, bvh)
    
    # Instantiate an Integrator
    I = BDPTIntegrator(C, S, parsed_args["max-depth"])
    return I, scene
end
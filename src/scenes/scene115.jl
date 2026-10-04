function make_scene115(parsed_args::Dict)::Tuple{AbstractIntegrator, Scene}
    primitives = Primitive[]
    lights = AbstractLight[]
    materials = AbstractMaterial[]

    # MATERIALS
    mat_gray = Matte(
        "mat_gray",
        ConstantTexture(spectrum_from_float(.4, .4, .4)),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_gray)

    mat_blue = Matte(
        "mat_blue",
        ConstantTexture(spectrum_from_float(0.05, 0.05, .9)),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_blue)

    mat_red = Matte(
        "mat_red",
        ConstantTexture(spectrum_from_float(0.9, 0.05, 0.1)),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_red)

    mat_green = Matte(
        "mat_green",
        ConstantTexture(spectrum_from_float(0.1, 0.92, 0.15)),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_green)

    mat_yellow = Matte(
        "mat_yellow",
        ConstantTexture(spectrum_from_float(0.9, 0.92, 0.18)),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_yellow)

    name_index = Dict(mat.name => i for (i, mat) in enumerate(materials))
    MATERIAL_REGISTRY[] = MaterialRegistry(materials, name_index)

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

    ##############
    ### Part 1 ###
    ##############
    axes   = (Vec3(1, 1, 1), Vec3(1, -1, -1), Vec3(-1, 1, -1), Vec3(-1, -1, 1))
    mats   = ("mat_red", "mat_blue", "mat_green", "mat_yellow")
    B      = Pnt3(1, 1, 1)
    E      = 0.14
    theta  = 20.0
    offset = 0.3

    # global tilt: takes the (1,1,1) diagonal to +y
    G = Rotate(-54.7356, Vec3(1, 0, -1))

    for (ax, mat) in zip(axes, mats)
        T = G * Translate(normalize(ax) * offset) * Rotate(theta, ax)
        box = SDFFrameBox(B, E, ShapeCore(T, Inv(T), false, false))
        push!(primitives, Primitive(box, mat, nothing))
    end
    

    #############
    ## PART 2 ###
    #############

    s = 100
    quad = SDFQuad(
        Vec3(-s, -3, -s),
        Vec3(s, -3, -s),
        Vec3(s, -3, s),
        Vec3(-s, -3, s),
        ShapeCore(),
    )
    push!(primitives, Primitive(quad, "mat_gray", nothing))

    #########################
    #########################

    # instantiate accelerator
    print("\nThere are " * num2str(length(primitives)) * " objects in the scene, building BVH\n")
    @time bvh = BVH(primitives)
    print("Done building BVH\n")

    l_2_w = Translate(Pnt3(0,0,0))
    light = InfiniteLight(
        world_bounds(bvh), 
        l_2_w, 
        Spectrum(1.0, 1.0, 1.0), 
        jmfp("/Users/johnmyslinski/Documents/pbrt-v4-scenes/clouds/textures/sky.exr"),
        true
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
    look_from = Pnt3(5, 3.5, 2.5)
    look_at = Pnt3(0, 0, 0)
    up = Vec3(0, 1, 0)
    C = PerspectiveCamera(LookAt(look_from, look_at, up), nothing, 0.0, 1.0, 0.0, 1e6, 75.0, film)

    # Instantiate a Sampler
    S = StratifiedSampler(parsed_args["samples-per-pixel"], parsed_args["jitter"])
    print("Using " * num2str(S.samples_per_pixel) * " samples per pixel\n")
    
    # Instantiate Scene
    print("There are " * num2str(length(lights)) * " lights in the scene\n")
    scene = Scene(lights, bvh)
    
    # Instantiate an Integrator (default: BDPT)
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
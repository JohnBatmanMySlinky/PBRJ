function make_scene15(parsed_args::Dict)::Tuple{AbstractIntegrator, Scene}
    primitives = Primitive[]
    lights = Light[]

    # Bounding sphere cause we hate winding order and such
    sphere_transform = Translate(Pnt3(0.5, 0.5, 0.5))
    sphere = Sphere(
        ShapeCore(
            sphere_transform,
            Inv(sphere_transform),
            false,
            false
        ),
        1.0
    )

    cloud_mi = MediumInterface(
        CloudMedium(
            Bounds3(Pnt3(0.0), Pnt3(1.0)),
            Translate(Pnt3(0,0,0)),
            spectrum_from_float(0.01),
            spectrum_from_float(10.0),
            HenyeyGreenstein(0.0),
            2.0, # density
            1.0, # wispiness
            5.0, # frequency
        ),
        nothing
    )
    push!(primitives, Primitive(sphere, nothing, nothing, cloud_mi))

    # instantiate accelerator
    print("\nThere are " * num2str(length(primitives)) * " objects in the scene, building BVH\n")
    @time bvh = BVH(primitives)
    print("Done building BVH\n")

    # instantiate the infinite light
    l_2_w = Translate(Pnt3(0,0,0))
    light = InfiniteLight(
        world_bounds(bvh), 
        l_2_w, 
        Spectrum(8.0, 8.0, 8.0), 
        jmfp("/Users/johnmyslinski/Documents/pbrt-v4-scenes/clouds/textures/sky.exr"),
        true
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
    look_from = Pnt3(.5, .8, -.5)
    look_at = Pnt3(.5, .7, .5)
    up = Vec3(0, 1, 0)
    C = PerspectiveCamera(LookAt(look_from, look_at, up), nothing, 0.0, 1.0, 0.0, 1e6, 35.0, film)

    # Instantiate a Sampler
    S = ZSobolSampler(parsed_args["samples-per-pixel"], Pnt2(parsed_args["image-dim"], parsed_args["image-dim"]), Int8(2))
    # S = StratifiedSampler(parsed_args["samples-per-pixel"], parsed_args["jitter"])
    print("Using " * num2str(S.samples_per_pixel) * " samples per pixel\n")
    
    # Instantiate Scene
    print("There are " * num2str(length(lights)) * " lights in the scene\n")
    scene = Scene(lights, bvh)
    
    # Instantiate an Integrator (default: SimpleVolPath)
    integrator_arg = parsed_args["integrator"]
    if integrator_arg == "default"
        I = SimpleVolPathIntegratorv4(C, S, parsed_args["max-depth"])
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
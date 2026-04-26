function make_scene103(parsed_args::Dict)::Tuple{AbstractIntegrator, Scene}
    primitives = Primitive[]
    lights = Light[]
    materials = Material[]

    # MATERIALS
    mat_checker = Matte(
        "mat_checker",
        NoiseTexture(
            spectrum_from_float(1.0),
            0.05,
            0.5,
            8,
            "perlin",
            nothing
        ),
        ConstantTexture(0.0),
        nothing,
    )
    push!(materials, mat_checker)

    name_index = Dict(mat.name => i for (i, mat) in enumerate(materials))
    MATERIAL_REGISTRY[] = MaterialRegistry(materials, name_index)

    # instantiate objects
    identity_shape_core = ShapeCore(
        Translate(Pnt3(0.0)),
        Translate(Pnt3(0.0)),
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
        push!(primitives, Primitive(tri, "mat_checker", nothing))
    end

    # instantiate accelerator
    print("\nThere are " * num2str(length(primitives)) * " objects in the scene, building BVH\n")
    @time bvh = BVH(primitives)
    print("Done building BVH\n")

    l_2_w = Translate(Pnt3(0,0,0))
    light = UniformInfiniteLight(
        world_bounds(bvh), 
        l_2_w, 
        Spectrum(1.0, 1.0, 1.0), 
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
    look_from = Pnt3(278, 278, -800)
    look_at = Pnt3(278, 278, 0)
    up = Vec3(0, 1, 0)
    C = PerspectiveCamera(LookAt(look_from, look_at, up), nothing, 0.0, 1.0, 0.0, 1e6, 40.0, film)

    # Instantiate a Sampler
    S = StratifiedSampler(parsed_args["samples-per-pixel"], parsed_args["jitter"])
    print("Using " * num2str(S.samples_per_pixel) * " samples per pixel\n")
    
    # Instantiate Scene
    print("There are " * num2str(length(lights)) * " lights in the scene\n")
    scene = Scene(lights, bvh)
    
    # Instantiate an Integrator (default: BDPT)
    integrator_arg = parsed_args["integrator"]
    if integrator_arg == "default"
        I = BDPTIntegrator(C, S, parsed_args["max-depth"])
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
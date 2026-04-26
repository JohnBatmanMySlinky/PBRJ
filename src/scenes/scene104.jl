function make_scene104(parsed_args::Dict)::Tuple{AbstractIntegrator, Scene}
    primitives = Primitive[]
    lights = Light[]
    materials = Material[]

    # MATERIALS
    mat_floor = Matte(
        "mat_floor",
        ConstantTexture(spectrum_from_float(0.5, 0.5, 0.5)),
        ConstantTexture(0.0),
        nothing,
    )
    push!(materials, mat_floor)

    mat_sphere = Matte(
        "mat_sphere",
        # MixMultTexture(
        #     ImageTexture(
        #         UVMapping2D(),
        #         jmfp("/Users/johnmyslinski/Documents/PBRJ/src/notebooks/colorful_grid_seed_42_5x9.png"),
        #         false
        #     ),
        #     ConstantTexture(spectrum_from_float(1.0, 1.0, 1.0))
        # ),
        ConstantTexture(spectrum_from_float(0.5, 0.5, 0.5)),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_sphere)

    name_index = Dict(mat.name => i for (i, mat) in enumerate(materials))
    MATERIAL_REGISTRY[] = MaterialRegistry(materials, name_index)

    # instantiate objects
    ########### Floor
    foyer_dim = 600
    floor_transform = Translate(Pnt3(0,0,0))
    floor = Rectangle(
        Pnt2(-foyer_dim/2, -foyer_dim/2), 
        Pnt2(foyer_dim/2, foyer_dim/2), 
        0.0,
        2, 
        ShapeCore(floor_transform, Inv(floor_transform), false, false),
        false,
        nothing
    )
    for tri in floor
        push!(primitives, Primitive(tri, "mat_floor", nothing))
    end

    ########## Sphere
    # sphere_radius = 5.0
    # sphere_t = Translate(Pnt3(0, sphere_radius + 3, 0))
    # sphere = Sphere(
    #     ShapeCore(sphere_t, Inv(sphere_t), false, false),
    #     sphere_radius
    # )
    # push!(primitives, Primitive(sphere, "mat_sphere", nothing))


    # alight = DiffuseAreaLight(
    #     spectrum_from_float(1.0, 1.0, 1.0),
    #     sphere,
    #     false,
    #     nothing,
    #     jmfp("/Users/johnmyslinski/Documents/PBRJ/src/notebooks/colorful_grid_seed_42_5x9.png"),
    #     10.0
    # )
    # push!(lights, alight)

    # instantiate accelerator
    print("\nThere are " * num2str(length(primitives)) * " objects in the scene, building BVH\n")
    @time bvh = BVH(primitives)
    print("Done building BVH\n")

    l_2_w = Translate(Pnt3(0,0,0))
    light = UniformInfiniteLight(
        world_bounds(bvh), 
        l_2_w, 
        Spectrum(0.5, 0.5, 0.5), 
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
    look_from = Pnt3(20, 20, 20)
    look_at = Pnt3(0, 0, 0)
    up = Vec3(0, 1, 0)
    C = PerspectiveCamera(LookAt(look_from, look_at, up), nothing, 0.0, 1.0, 0.0, 1e6, 45.0, film)

    # Instantiate a Sampler
    S = SamplerFactory(parsed_args)
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
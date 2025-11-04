function make_scene104(parsed_args::Dict)::Tuple{AbstractIntegrator, Scene}
    primitives = Primitive[]
    lights = Light[]
    materials = Material[]

    # MATERIALS
    mat_floor = Matte(
        "mat_floor",
        ImageTexture(
            UVMapping2D(),
            jmfp("/home/jmyslinski/random_stuff/PBRJ/src/notebooks/colorful_grid_seed_42_5x9.png"),
            false
        ),
        ConstantTexture(0.0),
        nothing,
    )
    push!(materials, mat_floor)

    name_index = Dict(mat.name => i for (i, mat) in enumerate(materials))
    MATERIAL_REGISTRY[] = MaterialRegistry(materials, name_index)

    # instantiate objects
    identity_shape_core = ShapeCore(
        Translate(Pnt3(0.0)),
        Translate(Pnt3(0.0)),
        false,
        false
    )
    sphere = Sphere(
        identity_shape_core, 
        5.0
    )
    push!(primitives, Primitive(sphere, "mat_floor", nothing))

    # instantiate accelerator
    print("\nThere are " * num2str(length(primitives)) * " objects in the scene, building BVH\n")
    @time bvh = BVH(primitives)
    print("Done building BVH\n")

    l_2_w = Translate(Pnt3(0,0,0))
    light = InfiniteLight(
        world_bounds(bvh),
        l_2_w,
        spectrum_from_float(1.0),
        jmfp("/home/jmyslinski/random_stuff/PBRJ/src/notebooks/solid_grid_2x2.png"),
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
    look_from = Pnt3(10, 10, 10)
    look_at = Pnt3(0, 0, 0)
    up = Vec3(0, 1, 0)
    C = PerspectiveCamera(LookAt(look_from, look_at, up), 0.0, 1.0, 0.0, 1e6, 45.0, film)

    # Instantiate a Sampler
    S = DumbSampler(parsed_args["samples-per-pixel"])
    print("Using " * num2str(S.samples_per_pixel) * " samples per pixel\n")
    
    # Instantiate Scene
    print("There are " * num2str(length(lights)) * " lights in the scene\n")
    scene = Scene(lights, bvh)
    
    # Instantiate an Integrator
    I = BDPTIntegrator(C, S, parsed_args["max-depth"])

    return I, scene
end
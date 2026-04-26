function make_scene19(parsed_args::Dict)::Tuple{AbstractIntegrator, Scene}
    primitives = Primitive[]
    lights = Light[]
    materials = Material[]

    # materials
    mat_disk = Matte(
        "mat_disk",
        ConstantTexture(spectrum_from_float(.4, .45, .35)),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_disk)

    name_index = Dict(mat.name => i for (i, mat) in enumerate(materials))
    MATERIAL_REGISTRY[] = MaterialRegistry(materials, name_index)

    # Bounding sphere cause we hate winding order and such
    sphere_transform = Translate(Pnt3(0,0,0))
    sphere = Sphere(
        ShapeCore(
            sphere_transform,
            Inv(sphere_transform),
            false,
            false
        ),
        45.0
    )

    smoke_mi = MediumInterface(
        NanoVDBMedium(
            RotateZ(180.0) * RotateX(90.0),
            spectrum_from_float(0.5),
            spectrum_from_float(10.0),
            0.0,
            1.0,
            jmfp("/Users/johnmyslinski/Documents/pbrt-v4-scenes/bunny-cloud/bunny_cloud.nvdb"),
            Pnt3i(256, 256, 256)
        ),
        nothing
    )
    push!(primitives, Primitive(sphere, nothing, nothing, smoke_mi))

    # The disk
    disk_t = Translate(Pnt3(0, -50, 0))
    disk = Disk(
        disk_t, 
        0.0,
        1_000.0, 
        0.0,
        360.0,
        false,
        false
    )
    push!(primitives, Primitive(disk, "mat_disk", nothing))


    # instantiate accelerator
    print("\nThere are " * num2str(length(primitives)) * " objects in the scene, building BVH\n")
    @time bvh = BVH(primitives)
    print("Done building BVH\n")

    # instantiate the infinite light
    l_2_w = RotateX(10.0)
    light = InfiniteLight(
        world_bounds(bvh), 
        l_2_w, 
        spectrum_from_float(4.0, Illuminant), 
        jmfp("/Users/johnmyslinski/Documents/pbrt-v4-scenes/bunny-cloud/textures/sky.exr"),
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
    look_from = Pnt3(0, 120, 50)
    look_at = Pnt3(7, 0, 17)
    up = Vec3(0, 0, 1)
    C = PerspectiveCamera(LookAt(look_from, look_at, up), nothing, 0.0, 1.0, 0.0, 1e6, 25.0, film)

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
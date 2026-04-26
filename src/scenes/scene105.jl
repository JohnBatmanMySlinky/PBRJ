function make_scene105(parsed_args::Dict)::Tuple{AbstractIntegrator, Scene}
    primitives = Primitive[]
    lights = Light[]
    materials = Material[]

    # MATERIALS
    mat_head = KdSubSurface(
        "mat_head",
        ImageTexture(
            UVMapping2D(),
            jmfp("/home/jmyslinski/random_stuff/pbrt-v3-scenes/head/textures/head_albedomap.png"),
            false
        ),
        ConstantTexture(spectrum_from_float(1.0, 1.0, 1.0)),
        ConstantTexture(spectrum_from_float(1.0, 1.0, 1.0)),
        ConstantTexture(spectrum_from_float(1.2953e-03, 9.5238e-04, 6.7114e-04)),
        ConstantTexture(0.05),
        ConstantTexture(0.05),
        1.0,
        1.33,
        0.0,
        nothing,
        false
    )
    push!(materials, mat_head)

    name_index = Dict(mat.name => i for (i, mat) in enumerate(materials))
    MATERIAL_REGISTRY[] = MaterialRegistry(materials, name_index)

    # instantiate objects
    head_t = Translate(Pnt3(0,0,0)) 
    head = parse_obj(
        jmfp("/home/jmyslinski/random_stuff/pbrt-v3-scenes/head/geometry/head_ascii.obj"),
        head_t,
        false,
        false,
        nothing
    )
    for tris in head
        for tri in tris
            push!(primitives, Primitive(tri, "mat_head", nothing))
        end
    end
  

    # instantiate accelerator
    print("\nThere are " * num2str(length(primitives)) * " objects in the scene, building BVH\n")
    @time bvh = BVH(primitives)
    print("Done building BVH\n")

    # l_2_w = Scale(Vec3(-1, 0, 0)) * Rotate(90.0, Vec3(-1, 0, 0)) * Rotate(90.0, Vec3(0, 0, 1))
    l_2_w = Translate(Pnt3(0,0,0))
    light = InfiniteLight(
        world_bounds(bvh),
        l_2_w,
        spectrum_from_float(1.0),
        jmfp("/home/jmyslinski/random_stuff/pbrt-v3-scenes/head/textures/doge2_latlong.exr"),
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
        4.0,
        parsed_args["file-name"]
    )

    # Instantiate a Camera
    look_from = Pnt3(0.322839, 0.0534825, 0.504299)
    look_at = Pnt3(-0.140808, -0.162727, -0.354936)
    up = Vec3(0.0355799, 0.964444, -0.261882)
    C = PerspectiveCamera(LookAt(look_from, look_at, up), nothing, 0.0, 1.0, 0.0, 1e6, 30.0, film)

    # Instantiate a Sampler
    S = SamplerFactory(parsed_args)
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
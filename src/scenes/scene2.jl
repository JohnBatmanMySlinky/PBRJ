function make_scene2(parsed_args::Dict)::Tuple{AbstractIntegrator, Scene}
    primitives = Primitive[]
    lights = Light[]
    materials = Material[]

    mat_floor = Uber(
        "mat_floor",
        ConstantTexture(spectrum_from_float(0.6399999857, 0.6399999857, 0.6399999857)),
        ConstantTexture(spectrum_from_float(0.1, 0.1, 0.1)),
        ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
        ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
        ConstantTexture(0.0104080001),
        nothing,
        nothing,
        ConstantTexture(1.0),
        ConstantTexture(spectrum_from_float(1.0)),
        nothing,
        true
    )
    push!(materials, mat_floor)

    mat_white = Matte(
        "mat_white",
        ConstantTexture(spectrum_from_float(1.0, 1.0, 1.0)),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_white)

    mat_glass = Glass(
        "mat_glass",
        ConstantTexture(spectrum_from_float(1.0, 1.0, 1.0)),
        ConstantTexture(spectrum_from_float(1.0, 1.0, 1.0)),
        ConstantTexture(0.0),
        ConstantTexture(0.0),
        ConstantTexture(1.25),
        nothing,
        true
    )
    push!(materials, mat_glass)

    name_index = Dict(mat.name => i for (i, mat) in enumerate(materials))
    MATERIAL_REGISTRY[] = MaterialRegistry(materials, name_index)

    # GEOMETRY
    # blue sphere
    glass_translate = Translate(Pnt3(0,0,0)) 
    glass = parse_obj(
        jmfp("/home/jmyslinski/random_stuff/PBRJ/ref/caustic-glass/geometry/mesh_00001_ascii.obj"),
        glass_translate,
        false,
        false,
        nothing
    )
    for tris in glass
        for tri in tris
            push!(primitives, Primitive(tri, "mat_glass", nothing))
        end
    end

    # floor
    floor_transform = Translate(Pnt3(0,0,0))
    floor = parse_obj(
        jmfp("/home/jmyslinski/random_stuff/PBRJ/ref/caustic-glass/geometry/mesh_00002_ascii.obj"),
        floor_transform,
        false,
        false,
        nothing
    )
    for tris in floor
        for tri in tris
            push!(primitives, Primitive(tri, "mat_floor", nothing))
        end
    end

    # instantiate accelerator
    print("\nThere are " * num2str(length(primitives)) * " objects in the scene, building BVH\n")
    @time bvh = BVH(primitives)
    print("Done building BVH\n")

    # spot light
    spot_light = SpotLight(
        LookAt(Pnt3(0,5,9), Pnt3(-5, 2.75, 0), Vec3(0,-1,0)), 
        spectrum_from_float(139.8113403320, 118.6366500854, 105.3887557983 ), 
        30.0, 
        5.0
    )
    push!(lights, spot_light)

    # l_2_w = Translate(Pnt3(0,0,0))
    # light = UniformInfiniteLight(
    #     world_bounds(bvh), 
    #     l_2_w, 
    #     Spectrum(0.1, 0.1, 0.1), 
    # )
    # push!(lights, light)

    # Instantiate a Filter
    filter = BoxFilter(Pnt2(.5, .5))

    # Instantiate a Film
    film = Film(
        Pnt2i(parsed_args["image-dim"][1], parsed_args["image-dim"][2]),
        Bounds2(Pnt2(parsed_args["crop-window"][1], parsed_args["crop-window"][2]), Pnt2(parsed_args["crop-window"][3], parsed_args["crop-window"][4])),
        filter,
        1.0,
        1.5,
        parsed_args["file-name"]
    )

    # Instantiate a Camera
    look_from = Pnt3(-5.5, 7, -5.5)
    look_at = Pnt3(-4.75, 2.25, 0)
    up = Vec3(0, 1, 0)
    C = PerspectiveCamera(LookAt(look_from, look_at, up), nothing, 0.0, 1.0, 0.0, 1e6, 30.0, film)

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
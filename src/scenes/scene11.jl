function make_scene11(parsed_args::Dict)::Tuple{AbstractIntegrator, Scene}
    primitives = Primitive[]
    lights = Light[]
    materials = Material[]

    # MATERIALS
    mat_ground = Matte(
        "mat_ground",
        ConstantTexture(spectrum_from_float(0.1, 0.1, 0.1)),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_ground)

    mat_metal = Metal(
        "mat_metal",
        ConstantTexture(spectrum_from_sampled(jmfp("/home/jmyslinski/random_stuff/pbrt-v3-scenes/dragon/spds/Au.eta.spd"))),
        ConstantTexture(spectrum_from_sampled(jmfp("/home/jmyslinski/random_stuff/pbrt-v3-scenes/dragon/spds/Au.k.spd"))),
        ConstantTexture(0.0),
    )
    push!(materials, mat_metal)

    mat_ceramic = Fourier(
        "mat_ceramic",
        jmfp("/Users/johnmyslinski/Documents/pbrt-v3-scenes/dragon/bsdfs/ceramic.bsdf"),
        nothing
    )
    push!(materials, mat_ceramic)

    mat_coated_copper = Fourier(
        "mat_coated_copper",
        jmfp("/Users/johnmyslinski/Documents/pbrt-v3-scenes/dragon/bsdfs/coated_copper.bsdf"),
        nothing
    )
    push!(materials, mat_coated_copper)

    mat_roughgold = Fourier(
        "mat_roughgold",
        jmfp("/Users/johnmyslinski/Documents/pbrt-v3-scenes/dragon/bsdfs/roughgold_alpha_0.2.bsdf"),
        nothing
    )
    push!(materials, mat_roughgold)

    name_index = Dict(mat.name => i for (i, mat) in enumerate(materials))
    MATERIAL_REGISTRY[] = MaterialRegistry(materials, name_index)

    # instantiate objects
    floor_t = Translate(Pnt3(0, 0, -40))
    foor_sc = ShapeCore(
        floor_t,
        Inv(floor_t),
        false,
        false
    )
    floor = Rectangle(
        Pnt2(-1000, -1000), 
        Pnt2(1000, 1000), 
        0.0,
        3, 
        foor_sc,
        false,
        nothing
    )
    for tri in floor
        push!(primitives, Primitive(tri, "mat_ground", nothing))
    end

    dragon_translate = RotateY(-53.0)
    dragon =  parse_obj(
        jmfp("/Users/johnmyslinski/Documents/pbrt-v3-scenes/dragon/geometry/dragon_remeshed_ascii.obj"),
        dragon_translate,
        false,
        false,
        nothing
    )
    for tris in dragon
        for tri in tris
            push!(primitives, Primitive(tri, "mat_coated_copper", nothing))
        end
    end

    # instantiate accelerator
    print("\nThere are " * num2str(length(primitives)) * " objects in the scene, building BVH\n")
    @time bvh = BVH(primitives)
    print("Done building BVH\n")

    # instantiate the infinite light
    l_2_w = Translate(Pnt3(0,0,0))
    light = InfiniteLight(
        world_bounds(bvh), 
        l_2_w, 
        spectrum_from_float(2.0, Illuminant), 
        jmfp("/Users/johnmyslinski/Documents/pbrt-v3-scenes/cloud/textures/skylight-morn.exr"),
        # "/Users/johnmyslinski/Documents/PBRJ/scratch/mipmap/hello.exr"
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
    look_from = Pnt3(277, -240, 250)
    look_at = Pnt3(0, 60, -30)
    up = Vec3(0, 0, 1)
    C = PerspectiveCamera(LookAt(look_from, look_at, up), nothing, 0.0, 1.0, 0.0, 1e6, 33.0, film)

    # Instantiate a Sampler
    S = StratifiedSampler(parsed_args["samples-per-pixel"], parsed_args["jitter"])
    print("Using " * num2str(S.samples_per_pixel) * " samples per pixel\n")
    
    # Instantiate Scene
    print("There are " * num2str(length(lights)) * " lights in the scene\n")
    scene = Scene(lights, bvh)
    
    # Instantiate an Integrator
    # I = BDPTIntegrator(C, S, parsed_args["max-depth"])
    I = VolPathIntegratorv3(C, S, parsed_args["max-depth"])

    return I, scene
end
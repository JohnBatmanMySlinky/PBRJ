function make_scene107(parsed_args::Dict)::Tuple{AbstractIntegrator, Scene}
    primitives = Primitive[]
    lights = Light[]
    materials = Material[]

    # MATERIALS
    mat_gray = Matte(
        "mat_gray",
        ConstantTexture(spectrum_from_float(0.5)),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_gray)
    name_index = Dict(mat.name => i for (i, mat) in enumerate(materials))
    MATERIAL_REGISTRY[] = MaterialRegistry(materials, name_index)

    # instantiate objects
    text_t = Translate(Pnt3(0, 0, 0))
    text = parse_obj_3dsmax_2011(
        jmfp("/home/jmyslinski/random_stuff/PBRJ/ref/train_station/test.obj"),
        text_t,
        false,
        false,
        nothing
    )
    for tris in text
        for tri in tris
            push!(primitives, Primitive(tri, "mat_gray", nothing))
        end
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
    LA_matrix = Mat4(
        0.59123,    0.0602817,  0.804247,   0.0,
        0.806503,   -0.0441912, -0.589576,  0.0,
        0.0,        0.997203,   -0.0747446, 0.0,
        134.241,    -123.776,   14.3307,    1.0
    )
    C = PerspectiveCamera(Transformation(LA_matrix, inv(LA_matrix)), nothing, 0.0, 1.0, 0.0, 1e6, 28.8415038750464, film)

    # Instantiate a Sampler
    S = SamplerFactory(parsed_args)
    print("Using " * num2str(S.samples_per_pixel) * " samples per pixel\n")
    
    # Instantiate Scene
    print("There are " * num2str(length(lights)) * " lights in the scene\n")
    scene = Scene(lights, bvh)
    
    # Instantiate an Integrator
    I = VolPathIntegratorv3(C, S, parsed_args["max-depth"])

    return I, scene
end
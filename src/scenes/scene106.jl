function make_scene106(parsed_args::Dict)::Tuple{AbstractIntegrator, Scene}
    primitives = Primitive[]
    lights = Light[]
    materials = Material[]

    # MATERIALS
    mat_subsurface = KdSubSurface(
        "mat_subsurface",
        ConstantTexture(spectrum_from_float(0.22, 0.596, .149)),
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
    push!(materials, mat_subsurface)

    mat_gray = Matte(
        "mat_gray",
        ConstantTexture(spectrum_from_float(.4, .4, .4)),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_gray)

    mat_green = Matte(
        "mat_green",
        ConstantTexture(spectrum_from_float(0.22, 0.596, .149)),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_green)

    name_index = Dict(mat.name => i for (i, mat) in enumerate(materials))
    MATERIAL_REGISTRY[] = MaterialRegistry(materials, name_index)

    # instantiate objects
    teapot_scale = 0.05
    teapot_t1 = Scale(Vec3(teapot_scale, teapot_scale, teapot_scale))
    teapot1 = parse_obj("../ref/teapot.obj", teapot_t1, false, false, nothing) 
    for tris in teapot1
        for tri in tris
            push!(primitives, Primitive(tri, "mat_subsurface", nothing))
        end
    end

    sc = ShapeCore()
    ground_tris = Rectangle(Pnt2(-10, -10), Pnt2(10, 10), -4.0, 2, sc, false, nothing)
    for tri in ground_tris
        push!(primitives, Primitive(tri, "mat_gray", nothing))
    end

    # instantiate accelerator
    print("\nThere are " * num2str(length(primitives)) * " objects in the scene, building BVH\n")
    @time bvh = BVH(primitives)
    print("Done building BVH\n")

    # l_2_w = Scale(Vec3(-1, 0, 0)) * Rotate(90.0, Vec3(-1, 0, 0)) * Rotate(90.0, Vec3(0, 0, 1))
    l_2_w = Rotate(-10.0, Vec3(0,0,1)) * Rotate(-160.0, Vec3(0,1,0)) * Rotate(-90.0, Vec3(1,0,0)) 
    light = InfiniteLight(
        world_bounds(bvh),
        l_2_w,
        spectrum_from_float(1.0),
        jmfp("/Users/johnmyslinski/Documents/pbrt-v3-scenes/barcelona-pavilion/textures/sky.exr"),
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
    look_from = Pnt3(20.0, 20.0, 20.0)
    look_at = Pnt3(0, 0, 0)
    up = Vec3(0, 1, 0)
    C = PerspectiveCamera(LookAt(look_from, look_at, up), 0.0, 1.0, 0.0, 1e6, 30.0, film)

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
function make_scene106(parsed_args::Dict)::Tuple{AbstractIntegrator, Scene}
    primitives = Primitive[]
    lights = Light[]
    materials = Material[]

    # MATERIALS
    sigma_a, sigma_s = SUBSURFACE_PARAMS["Skin1"]
    mat_skin = SubSurface(
        "mat_skin",
        ConstantTexture(spectrum_from_float(1.0)),
        ConstantTexture(spectrum_from_float(1.0)),
        ConstantTexture(sigma_a),
        ConstantTexture(sigma_s),
        ConstantTexture(0.0),
        ConstantTexture(0.0),
        10.0,
        1.5,
        0.0,
        nothing,
        true
    )
    push!(materials, mat_skin)

    mat_checker = Matte(
        "mat_checker",
        Checker2DTexture(
            spectrum_from_float(0.4, 0.4, 0.4),
            spectrum_from_float(0.2, 0.2, 0.2),
            Vec2(16.0, 16.0)
        ),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_checker)

    name_index = Dict(mat.name => i for (i, mat) in enumerate(materials))
    MATERIAL_REGISTRY[] = MaterialRegistry(materials, name_index)

    # instantiate objects
    # dragon_t = Translate(Pnt3(0.2, 0.3, 0.78)) * Rotate(90.0, Vec3(1, 0, 0)) * Rotate(-90.0, Vec3(0, 1, 0)) * Scale(Vec3(0.02, 0.02, 0.02))
    # dragon = parse_obj(
    #     jmfp("/Users/johnmyslinski/Documents/pbrt-v3-scenes/sssdragon/geometry/dragon_ascii.obj"),
    #     dragon_t,
    #     false,
    #     false,
    #     nothing
    # )
    # for tris in dragon
    #     for tri in tris
    #         push!(primitives, Primitive(tri, "mat_skin", nothing))
    #     end
    # end

    sphere_t = Translate(Pnt3(0.00325, 0.25559, 0.64526))
    sphere = Sphere(
        ShapeCore(sphere_t, Inv(sphere_t), false, false),
        0.75
    )
    push!(primitives, Primitive(sphere, "mat_skin", nothing))

    floor_t = Translate(Pnt3(0, 0, 0))
    floor = parse_obj(
        jmfp("/Users/johnmyslinski/Documents/pbrt-v3-scenes/sssdragon/geometry/meshes_0_ascii.obj"),
        floor_t,
        false,
        false,
        nothing
    )
    for tris in floor
        for tri in tris
            push!(primitives, Primitive(tri, "mat_checker", nothing))
        end
    end
  

    # instantiate accelerator
    print("\nThere are " * num2str(length(primitives)) * " objects in the scene, building BVH\n")
    @time bvh = BVH(primitives)
    print("Done building BVH\n")

    # l_2_w = Scale(Vec3(-1, 0, 0)) * Rotate(90.0, Vec3(-1, 0, 0)) * Rotate(90.0, Vec3(0, 0, 1))
    l_2_w_matrix = Mat4([-0.224951, 0.0, -0.97437, 0.0, -0.97437, 0.0, 0.224951, 0.0, 0.0, 1.0, 0.0, 8.87, 0.0, 0.0, 0.0, 1.0])
    l_2_w = Transformation(l_2_w_matrix, inv(l_2_w_matrix))
    light = InfiniteLight(
        world_bounds(bvh),
        l_2_w,
        spectrum_from_float(1.0),
        jmfp("/Users/johnmyslinski/Documents/pbrt-v3-scenes/sssdragon/textures/envmap.exr"),
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
    look_from = Pnt3(3.69558, -3.46243, 3.25463)
    look_at = Pnt3(3.04072, -2.85176, 2.80939)
    up = Vec3(-0.317366, 0.312466, 0.895346)
    C = PerspectiveCamera(LookAt(look_from, look_at, up), 0.0, 1.0, 0.0, 1e6, 28.8415038750464, film)

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
"""
             -z
           o |
           r |
           r |
           r |
     ttt     |
             |
             |
-x ----------|---------- x
             |
             |
             |     c
             |
             |
             z
"""



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

    mat_red = Matte(
        "# object Text001",
        ConstantTexture(spectrum_from_float(0.9, 0.1, 0.15)),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_red)

    name_index = Dict(mat.name => i for (i, mat) in enumerate(materials))
    MATERIAL_REGISTRY[] = MaterialRegistry(materials, name_index)

    # instantiate objects
    obj_t = Translate(Pnt3(0, 0, 0))
    obj, group_to_idx = parse_obj_3dsmax_2011(
        jmfp("/home/jmyslinski/random_stuff/PBRJ/ref/train_station/train_station_2.obj"),
        obj_t,
        false,
        false,
        nothing
    )
    for (i, tris) in enumerate(obj)
        for tri in tris
            if group_to_idx[i] == "# object Text001"
                push!(primitives, Primitive(tri, group_to_idx[i], nothing))
            else
                push!(primitives, Primitive(tri, "mat_gray", nothing))
            end
        end
    end

    # instantiate accelerator
    print("\nThere are " * num2str(length(primitives)) * " objects in the scene, building BVH\n")
    @time bvh = BVH(primitives)
    print("Done building BVH\n")

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
    look_from = Pnt3(150.0, 20.0, 55.0)
    look_at = Pnt3(-40.0, 30.0, -45.0)
    up = Vec3(0, 1, 0)
    C = PerspectiveCamera(LookAt(look_from, look_at, up) * Scale(-1.0, 1.0, 1.0), nothing, 0.0, 1.0, 0.0, 1e6, 37.0, film)

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
function make_scene17(parsed_args::Dict)::Tuple{AbstractIntegrator, Scene}
    primitives = Primitive[]
    lights = Light[]

    # MATERIALS
    mat_gray = Matte(
        ConstantTexture(spectrum_from_float(.9, .9, .795)),
        ConstantTexture(0.0),
        nothing
    )

    dirpath = "/Users/johnmyslinski/Documents/pbrt-v3-scenes/barcelona-pavilion/geometry/"
    objs = String[]
    for (_, _, files) in walkdir(dirpath)
        # LAZILY ignoring nested folders
        for file in files
            if endswith(file, ".obj")
                push!(objs, file)
            end
        end
    end
    for obj_file in objs
        if obj_file != "mesh_00114.obj"
            obj_path = joinpath(dirpath, obj_file)
            objects = parse_obj(
                obj_path,
                Translate(Pnt3(0,0,0)),
                false,
                false,
                nothing
            )
            for object in objects
                for mesh in object
                    push!(primitives, Primitive(mesh, mat_gray, nothing))
                end
            end
        end
    end

    # instantiate accelerator
    print("\nThere are " * num2str(length(primitives)) * " objects in the scene, building BVH\n")
    @time bvh = BVH(primitives)
    print("Done building BVH\n")

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
    
    light_t = Rotate(-10.0, Vec3(0,0,1)) * Rotate(-160.0, Vec3(0,1,0)) * Rotate(-90.0, Vec3(1,0,0))
    light = InfiniteLight(
        world_bounds(bvh),
        light_t,
        spectrum_from_float(1.0),
        "/Users/johnmyslinski/Documents/pbrt-v3-scenes/barcelona-pavilion/textures/sky.exr",
        false
    )
    push!(lights, light)

    # Instantiate a Camera
    look_from = Pnt3(-15, 6, -10) #-15, 6, -1
    look_at = Pnt3(0, 0, -5)
    up = Vec3(0, 1, 0)
    screen = Bounds2(Pnt2(-1, -1), Pnt2(1, 1))
    C = PerspectiveCamera(LookAt(look_from, look_at, up), screen, 0.0, 1.0, 0.0, 1e6, 45.0, film)

    # Instantiate a Sampler
    S = ZSobolSampler(parsed_args["samples-per-pixel"], film.full_resolution, Int8(2))
    print("Using " * num2str(S.samples_per_pixel) * " samples per pixel\n")
    
    # Instantiate Scene
    print("There are " * num2str(length(lights)) * " lights in the scene\n")
    scene = Scene(lights, bvh)
    
    # Instantiate an Integrator
    I = BDPTIntegrator(C, S, parsed_args["max-depth"])
    return I, scene
end
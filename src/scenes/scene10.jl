function make_scene10(parsed_args::Dict)::Tuple{AbstractIntegrator, Scene}
    primitives = Primitive[]
    lights = Light[]

    mat_disk = Matte(
        ConstantTexture(spectrum_from_float(0.1, 0.1, 0.1)),
        ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
        nothing
    )
    
    # Bounding sphere cause we hate winding order and such
    sphere_transform = Translate(Pnt3(0.25, 0.0, -1.2)) * RotateX(90.0) 
    sphere = Sphere(
        ShapeCore(
            sphere_transform,
            Inv(sphere_transform),
            false,
            false
        ),
        1.4
    )
    smoke_t = Translate(Pnt3(-1.0, 0.0, -1.2)) * RotateX(90.0)
    smoke_mi = MediumInterface(
        GridMedium(
            jmfp("/Users/johnmyslinski/Documents/pbrt-v3-scenes/cloud/geometry/density_render.70.pbrt"),
            smoke_t,
            spectrum_from_float(90.0),
            spectrum_from_float(10.0),
            1.0,
            Pnt3(0.01, 0.01, 0.01),
            Pnt3(1.99, 1.99, 0.79),
            0.0,
            Pnt3(256, 256, 256)
        ),
        nothing
    )
    push!(primitives, Primitive(sphere, nothing, nothing, smoke_mi))
    # push!(primitives, Primitive(sphere, mat_white, nothing))

    look_from = Pnt3(0.0715308, -4.17677, 5.33558)
    look_at = Pnt3(0.0720194, -3.62456, 4.50187)
    up = Vec3(-0.000323605, 0.833706, 0.552208)
    camera_transform = LookAt(look_from, look_at, up) * Scale(-1.0, 1.0, 1.0)
    disk = Disk(
        camera_transform * Translate(Pnt3(0, 0, 30)),
        30.0,
        false,
        false
    )
    push!(primitives, Primitive(disk, mat_disk, nothing))

    # instantiate accelerator
    print("\nThere are " * num2str(length(primitives)) * " objects in the scene, building BVH\n")
    @time bvh = BVH(primitives)
    print("Done building BVH\n")

    # instantiate the infinite light
    l_2_w = Translate(Pnt3(0,0,0))
    light = InfiniteLight(
        world_bounds(bvh), 
        l_2_w, 
        spectrum_from_float(3.0, Illuminant), 
        jmfp("/Users/johnmyslinski/Documents/pbrt-v3-scenes/cloud/textures/skylight-morn.exr")
        # "/Users/johnmyslinski/Documents/PBRJ/scratch/mipmap/hello.exr"
    )
    push!(lights, light)

    # Instantiate a Filter
    filter = BoxFilter(Pnt2(.5, .5))

    # Instantiate a Film
    film = Film(
        Pnt2(parsed_args["image-dim"], parsed_args["image-dim"]),
        Bounds2(Pnt2(parsed_args["crop-window"][1], parsed_args["crop-window"][2]), Pnt2(parsed_args["crop-window"][3], parsed_args["crop-window"][4])),
        filter,
        1.0,
        7.0,
        parsed_args["file-name"]
    )

    # Instantiate a Camera

    screen = Bounds2(Pnt2(-1, -1), Pnt2(1, 1))
    C = PerspectiveCamera(camera_transform, screen, 0.0, 1.0, 0.0, 1e6, 15.0, film)

    # Instantiate a Sampler
    S = StratifiedSampler(parsed_args["samples-per-pixel"], parsed_args["jitter"])
    print("Using " * num2str(S.samples_per_pixel) * " samples per pixel\n")
    
    # Instantiate Scene
    print("There are " * num2str(length(lights)) * " lights in the scene\n")
    scene = Scene(lights, bvh)
    
    # Instantiate an Integrator
    # I = BDPTIntegrator(C, S, parsed_args["max-depth"])
    I = SimpleVolPathIntegrator(C, S, parsed_args["max-depth"])

    return I, scene
end
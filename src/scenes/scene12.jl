function make_scene12()::Tuple{AbstractIntegrator, Scene}
    primitives = Primitive[]
    lights = Light[]

    # Bounding sphere cause we hate winding order and such
    box_t = Translate(Pnt3(-0.5, -1.0, 0))
    sphere_transform = Translate(Pnt3(0, 0, 0))
    sphere = Sphere(
        ShapeCore(
            sphere_transform,
            Inv(sphere_transform),
            false,
            false
        ),
        5.0
    )
    smoke_mi = MediumInterface(
        GridDensityMedium(
            spectrum_from_float(10.0),
            spectrum_from_float(90.0),
            0.0,
            Pnt3(0.0, 0.0, 0.0),
            Pnt3(1.0, 1.0, 1.0),
            box_t,
            "/Users/johnmyslinski/Documents/pbrt-v3-scenes/cloud/geometry/density_render_cloud.pbrt"
        ),
        nothing
    )
    push!(primitives, Primitive(sphere, nothing, nothing, smoke_mi))

    # instantiate accelerator
    print("\nThere are " * num2str(length(primitives)) * " objects in the scene, building BVH\n")
    @time bvh = BVH(primitives)
    print("Done building BVH\n")

    # instantiate the infinite light
    l_2_w = Translate(Pnt3(0,0,0))
    light = InfiniteLight(
        world_bounds(bvh), 
        l_2_w, 
        Spectrum(3.0, 3.0, 3.0), 
        "/Users/johnmyslinski/Documents/pbrt-v3-scenes/cloud/textures/skylight-morn.exr"
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
        1.0,
        parsed_args["file-name"]
    )

    # Instantiate a Camera
    look_from = Pnt3(0.0715308, 1.17677, 5.33558)
    look_at = Pnt3(0, 0, 0)
    up = Vec3(-0.000323605, 0.833706, 0.552208)
    screen = Bounds2(Pnt2(-1, -1), Pnt2(1, 1))
    C = PerspectiveCamera(LookAt(look_from, look_at, up), screen, 0.0, 1.0, 0.0, 1e6, 25.0, film)

    # Instantiate a Sampler
    S = StratifiedSampler(parsed_args["samples-per-pixel"], parsed_args["jitter"])
    print("Using " * num2str(S.samples_per_pixel) * " samples per pixel\n")
    
    # Instantiate Scene
    print("There are " * num2str(length(lights)) * " lights in the scene\n")
    scene = Scene(lights, bvh)
    
    # Instantiate an Integrator
    I = BDPTIntegrator(C, S, parsed_args["max-depth"])

    return I, scene
end
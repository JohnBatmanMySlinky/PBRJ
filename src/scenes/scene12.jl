function make_scene12(parsed_args::Dict)::Tuple{AbstractIntegrator, Scene}
    primitives = Primitive[]
    lights = Light[]

    mat_sphere = Matte(
        ConstantTexture(spectrum_from_float(0.3, 0.3, 0.3)),
        ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
        nothing
    )

    sphere_transform = Translate(Pnt3(1, 1, -1)) * Rotate(180.0, Vec3(0, 1, 0)) * Translate(Pnt3(-0.75, 0, -0.75)) * Scale(2.0, 2.0, 2.0) * Translate(Pnt3(0.375, 0.0, 0.375))
    sphere = Sphere(
        ShapeCore(
            sphere_transform,
            Inv(sphere_transform),
            false,
            false
        ),
        0.1
    )
    push!(primitives, Primitive(sphere, mat_sphere, nothing))

    # instantiate accelerator
    print("\nThere are " * num2str(length(primitives)) * " objects in the scene, building BVH\n")
    @time bvh = BVH(primitives)
    print("Done building BVH\n")

    # instantiate the infinite light
    l_2_w = Rotate(-90.0, Vec3(1, 0, 0)) * Rotate(110.0, Vec3(0, 1, 0))
    light = InfiniteLight(
        world_bounds(bvh), 
        l_2_w, 
        Spectrum(4.0, 4.0, 4.0), 
        "/Users/johnmyslinski/Documents/pbrt-v4-scenes/smoke-plume/textures/sky.exr"
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
    look_from = Pnt3(1.0, 2.9, -10.5)
    look_at = Pnt3(1.0, 0.775, 0.0)
    up = Vec3(0, 1, 0)
    screen = Bounds2(Pnt2(-1, -1), Pnt2(1, 1))
    C = PerspectiveCamera(LookAt(look_from, look_at, up), screen, 0.0, 1.0, 0.0, 1e6, 8.0, film)

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
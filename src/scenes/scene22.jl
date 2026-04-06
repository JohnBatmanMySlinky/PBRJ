function make_scene22(parsed_args::Dict)::Tuple{AbstractIntegrator, Scene}
    primitives = Primitive[]
    lights = Light[]
    materials = Material[]

    name_index = Dict(mat.name => i for (i, mat) in enumerate(materials))
    MATERIAL_REGISTRY[] = MaterialRegistry(materials, name_index)

    # Bounding sphere enclosing the explosion mesh (~[-30,33] x [-0,89] x [-35,31])
    sphere_t = Translate(Pnt3(1.5, 45.0, -2.0))
    sphere = Sphere(
        ShapeCore(sphere_t, Inv(sphere_t), false, false),
        70.0
    )

    explosion_mi = MediumInterface(
        NanoVDBMedium(
            Translate(Pnt3(0, 0, 0)),                   # medium is already in world space
            spectrum_from_float(0.4, 0.4, 0.4), # sigma_a
            spectrum_from_float(0.9, 0.9, 0.9), # sigma_s
            0.0,                                # g
            5.0,                                # scale
            jmfp("/Users/johnmyslinski/Documents/pbrt-v4-volumes/scenes/ground_explosion/geometry/ground_explosion-RENDER-0.190.nvdb"),
            Pnt3i(16, 16, 16),
            0.125,                              # Le_scale
            0.0,                                # temperature_offset
            4500.0,                             # temperature_scale
        ),
        nothing
    )
    push!(primitives, Primitive(sphere, nothing, nothing, explosion_mi))

    print("\nThere are " * num2str(length(primitives)) * " objects in the scene, building BVH\n")
    @time bvh = BVH(primitives)
    print("Done building BVH\n")

    # Infinite light — low sun env map
    light = InfiniteLight(
        world_bounds(bvh),
        RotateX(7.0),
        spectrum_from_float(2.0, Illuminant),
        jmfp("/Users/johnmyslinski/Documents/pbrt-v4-volumes/scenes/ground_explosion/env/low_sun.exr"),
        true
    )
    push!(lights, light)

    filter = BoxFilter(Pnt2(0.5, 0.5))
    film = Film(
        Pnt2i(parsed_args["image-dim"][1], parsed_args["image-dim"][2]),
        Bounds2(Pnt2(parsed_args["crop-window"][1], parsed_args["crop-window"][2]), Pnt2(parsed_args["crop-window"][3], parsed_args["crop-window"][4])),
        filter,
        1.0,
        1.0,
        parsed_args["file-name"]
    )

    # Camera: positioned to match pbrt's transform — above and back, looking at explosion center
    look_from = Pnt3(1.5, -80.0, 160.0)
    look_at   = Pnt3(1.5, 45.0, 10.0)
    up        = Vec3(0.0, 0.0, 1.0)
    screen_window = Bounds2(Pnt2(-1, -0.75), Pnt2(1, 0.75))
    C = PerspectiveCamera(LookAt(look_from, look_at, up) * Scale(-1.0, 1.0, 1.0), nothing, 0.0, 1.0, 0.0, 1e6, 45.0, film)

    S = ZSobolSampler(
        parsed_args["samples-per-pixel"],
        Pnt2i(parsed_args["image-dim"][1], parsed_args["image-dim"][2]),
        Int8(2),
        parsed_args["seed"]
    )
    print("Using " * num2str(S.samples_per_pixel) * " samples per pixel\n")

    print("There are " * num2str(length(lights)) * " lights in the scene\n")
    scene = Scene(lights, bvh)

    I = SimpleVolPathIntegratorv4(C, S, parsed_args["max-depth"])

    return I, scene
end

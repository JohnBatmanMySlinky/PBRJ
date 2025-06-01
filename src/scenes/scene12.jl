function make_scene12(parsed_args::Dict)::Tuple{AbstractIntegrator, Scene}
    primitives = Primitive[]
    lights = Light[]

    mat_sphere = Metal(
        ConstantTexture(spectrum_from_sampled(jmfp("/home/jmyslinski/random_stuff/pbrt-v3-scenes/bathroom/spds/Ag.eta.spd"))),
        ConstantTexture(spectrum_from_sampled(jmfp("/home/jmyslinski/random_stuff/pbrt-v3-scenes/bathroom/spds/Ag.k.spd"))),
        ConstantTexture(0.0),
    )
    mat_floor = Matte(
        ConstantTexture(spectrum_from_float(0.025, 0.025, 0.025)),
        ConstantTexture(0.0),
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

    smoke_t = Translate(Pnt3(1, 0, -1)) * Rotate(180.0, Vec3(0,1,0)) * Translate(Pnt3(-0.75, 0.0, -0.75)) * Scale(2.0, 2.0, 2.0)
    sphere2 = Sphere(
        ShapeCore(
            smoke_t,
            Inv(smoke_t),
            false,
            false
        ),
        3.0
    )
    smoke_mi = MediumInterface(
        GridMedium(
            jmfp("/Users/johnmyslinski/Documents/pbrt-v4-scenes/smoke-plume/geometry/density_big_0084.pbrt"),
            smoke_t,
            spectrum_from_float(20.0),
            spectrum_from_float(160.0),
            1.0,
            spectrum_from_float(0.0),
            1.0,
            0.0,
            Pnt3i(256, 256, 256)
        ),
        nothing
    )
    push!(primitives, Primitive(sphere2, nothing, nothing, smoke_mi))

    floor_t = Translate(Pnt3(0, 0.1, 0))
    floor = BilinearPatchGenerator(
        ShapeCore(floor_t, Inv(floor_t), false, false),
        1,
        Pnt3[Pnt3(-50, 0, -50), Pnt3(-50, 0, 50), Pnt3(50, 0, -50), Pnt3(50, 0, 50)],
        Int64[1, 2, 3, 4],
        nothing,
        nothing,
        nothing,
        nothing,
        nothing
    )
    for tri in floor
        push!(primitives, Primitive(tri, mat_floor, nothing))
    end

    # instantiate accelerator
    print("\nThere are " * num2str(length(primitives)) * " objects in the scene, building BVH\n")
    @time bvh = BVH(primitives)
    print("Done building BVH\n")

    # instantiate the infinite light
    l_2_w = Rotate(110.0, Vec3(0, 1, 0)) * Rotate(-90.0, Vec3(1, 0, 0))
    light = InfiniteLight(
        world_bounds(bvh), 
        l_2_w, 
        Spectrum(4.0, 4.0, 4.0), 
        jmfp("/Users/johnmyslinski/Documents/pbrt-v4-scenes/smoke-plume/textures/sky.exr"),
        true
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

function make_scene13(parsed_args::Dict)::Tuple{AbstractIntegrator, Scene}
    primitives = Primitive[]
    lights = Light[]

    # materials
    mat_gray = Matte(
        ConstantTexture(spectrum_from_float(0.5, 0.5, 0.5)),
        ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
        nothing
    )
    mat_disk = Matte(
        ConstantTexture(spectrum_from_float(0.3, 0.3, 0.3)),
        ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
        nothing
    )

    # Bounding sphere cause we hate winding order and such
    box_t = Translate(Pnt3(0, 0, 0))
    sphere_transform = Translate(Pnt3(-9.984, 73.008, -42.64)) * Scale(Vec3(206.544, 140.4, 254.592))
    sphere = Sphere(
        ShapeCore(
            sphere_transform,
            Inv(sphere_transform),
            false,
            false
        ),
        # 1.44224957031
        0.54224957031
    )
    # push!(primitives, Primitive(sphere, mat_gray, nothing))

    smoke_mi = MediumInterface(
        NanoVDBMedium(
            Translate(Pnt3(0,0,0)),
            spectrum_from_float(0.0),
            spectrum_from_float(1.0),
            4.0,
            0.877,
            jmfp("/Users/johnmyslinski/Documents/pbrt-v4-scenes/disney-cloud/wdas_cloud_quarter.nvdb"),
            Pnt3(3, 3, 3)
        ),
        nothing
    )
    push!(primitives, Primitive(sphere, nothing, nothing, smoke_mi))
    # push!(primitives, Primitive(sphere, mat_disk, nothing))

    # The disk
    disk_t = Translate(Pnt3(0, -1000, 0)) * Scale(2000.0, 2000.0, 2000.0) * Rotate(-90.0, Vec3(1, 0, 0))
    disk = Disk(
        disk_t, 
        0.0,
        1.0, 
        0.0,
        360.0,
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
    light = UniformInfiniteLight(
        world_bounds(bvh), 
        l_2_w, 
        Spectrum(0.03, 0.07, 0.23), 
        # Spectrum(2.3, 2.7, 2.3), 
    )
    push!(lights, light)

    # Distnat Light
    wb = world_bounds(bvh)
    world_center, world_radius = bounding_sphere(wb)
    light = DistantLight(
        # Spectrum(2.6, 2.5, 2.3),
        Spectrum(6.6, 6.5, 6.3),
        Vec3(0,0,0),
        Vec3(-0.5826, -0.7660, -0.2717),
        world_center,
        world_radius,
        l_2_w
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
    look_from = Pnt3(648.064, -82.473, -63.856)
    look_at = Pnt3(6.021, 100.043, -43.679)
    up = Vec3(0.273, 0.962, -0.009)
    screen = Bounds2(Pnt2(-1, -1), Pnt2(1, 1))
    C = PerspectiveCamera(Scale(-1.0, 1.0, 1.0) * LookAt(look_from, look_at, up), screen, 0.0, 1.0, 0.0, 1e6, 31.07, film)

    # Instantiate a Sampler
    S = ZSobolSampler(parsed_args["samples-per-pixel"], Pnt2(parsed_args["image-dim"], parsed_args["image-dim"]), Int8(2))
    print("Using " * num2str(S.samples_per_pixel) * " samples per pixel\n")
    
    # Instantiate Scene
    print("There are " * num2str(length(lights)) * " lights in the scene\n")
    scene = Scene(lights, bvh)
    
    # Instantiate an Integrator
    I = BDPTIntegrator(C, S, parsed_args["max-depth"])

    return I, scene
end
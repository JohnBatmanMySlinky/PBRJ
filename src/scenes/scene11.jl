function make_scene11(parsed_args::Dict)::Tuple{AbstractIntegrator, Scene}
    primitives = Primitive[]
    lights = Light[]

    # materials
    mat_gray = Matte(
        ConstantTexture(spectrum_from_float(0.6, 0.6, 0.6)),
        ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
        nothing
    )
    mat_blue = Matte(
        ConstantTexture(spectrum_from_float(0.2, 1.0, 0.2)),
        ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
        nothing
    )

    ###############
    ### a thing ###
    ###############       


    s = Sphere(ShapeCore(Translate(Pnt3(0, 0.025, 0)), Inv(Translate(Pnt3(0, 0.025, 0)))), .075)
    push!(primitives, Primitive(s, mat_blue, nothing))

    floor_transform = Translate(Pnt3(0,0,0))
    floor = Rectangle(
        Pnt2(-10, -10),
        Pnt2(10, 10),
        0.0,
        2, 
        ShapeCore(floor_transform, Inv(floor_transform), false, false),
        false,
        nothing
    )
    for tri in floor
        push!(primitives, Primitive(tri, mat_gray, nothing))
    end

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
        jmfp("/Users/johnmyslinski/Documents/pbrt-v3-scenes/cloud/textures/skylight-morn.exr")
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
    look_from = Pnt3(-.3, .5, -.5)
    look_at = Pnt3(0, 0.0, 0)
    up = Vec3(0, 1, 0)
    screen = Bounds2(Pnt2(-1, -1), Pnt2(1, 1))
    C = PerspectiveCamera(LookAt(look_from, look_at, up), screen, 0.0, 1.0, 0.0, 1e6, 37.0, film)

    # Instantiate a Sampler
    S = ZSobolSampler(
        parsed_args["samples-per-pixel"], 
        Pnt2(parsed_args["image-dim"], parsed_args["image-dim"]), 
        Int8(2)
    )
    print("Using " * num2str(S.samples_per_pixel) * " samples per pixel\n")
    
    # Instantiate Scene
    print("There are " * num2str(length(lights)) * " lights in the scene\n")
    scene = Scene(lights, bvh)
    
    # Instantiate an Integrator
    I = BDPTIntegrator(C, S, parsed_args["max-depth"])
    return I, scene
end
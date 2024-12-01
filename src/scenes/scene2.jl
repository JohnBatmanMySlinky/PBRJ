function make_scene2()::Tuple{AbstractIntegrator, Scene}
    primitives = Primitive[]
    lights = Light[]

    mat_gray = Matte(
        ConstantTexture(Vec3(.4, .4, .4)),
        ConstantTexture(Vec3(0, 0, 0)),
        nothing
    )
    mat_white = Matte(
        ConstantTexture(Vec3(1.0, 1.0, 1.0)),
        ConstantTexture(Vec3(0, 0, 0)),
        nothing
    )
    mat_glass = Glass(
        ConstantTexture(Pnt3(.85, .85, 1.0)),
        ConstantTexture(Pnt3(.85, .85, 1.0)),
        ConstantTexture(Pnt3(0.0)),
        ConstantTexture(Pnt3(0.0)),
        ConstantTexture(Pnt3(1.25)),
        nothing,
        true
    )

    # GEOMETRY
    # blue sphere
    glass_translate = Translate(Pnt3(0,0,0)) 
    glass =  parse_obj(
        "../ref/caustic-glass/caustic_glass.obj",
        glass_translate,
        true,
        false,
        nothing
    )

    for tri in glass
        push!(primitives, Primitive(tri, mat_glass, nothing))
    end

    # floor
    floor_transform = Translate(Pnt3(0,0,0))
    floor = Rectangle(
        Pnt2(-15, -15), 
        Pnt2(15, 15), 
        1.456639051,
        2, 
        ShapeCore(floor_transform, Inv(floor_transform), false, false),
        false,
        nothing
    )
    for tri in floor
        push!(primitives, Primitive(tri, mat_gray, nothing))
    end

    # spot light
    spot_light = SpotLight(
        LookAt(Pnt3(0,5,9), Pnt3(-5, 2.75, 0), Vec3(0,-1,0)), 
        spectrum_from_float(1390.8113403320, 1180.6366500854, 1050.3887557983 ), 
        30.0, 
        5.0
    )
    push!(lights, spot_light)

    # instantiate accelerator
    print("\nThere are " * num2str(length(primitives)) * " objects in the scene, building BVH\n")
    @time bvh = BVH(primitives)
    print("Done building BVH\n")

    # Instantiate a Filter
    filter = BoxFilter(Pnt2(.25, .25))

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
    look_from = Pnt3(-5.5, 7, -5.5)
    look_at = Pnt3(-4.75, 2.25, 0)
    up = Vec3(0, 1, 0)
    screen = Bounds2(Pnt2(-1, -1), Pnt2(1, 1))
    C = PerspectiveCamera(LookAt(look_from, look_at, up), screen, 0.0, 1.0, 0.0, 1e6, 30.0, film)

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
function make_scene3(parsed_args::Dict)::Tuple{AbstractIntegrator, Scene}
    primitives = Primitive[]
    primitives2 = Primitive[]
    lights = Light[]
    lights2 = Light[]

    # MATERIALS
    mat_white = Matte(
        ConstantTexture(spectrum_from_float(1.0, 1.0, 1.0)),
        ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
        nothing
    )

    # instantiate objects
    identity_shape_core = ShapeCore(
        Translate(Pnt3(0)),
        Translate(Pnt3(0)),
        false,
        false
    )
    floor = Rectangle(
        Pnt2(-250, -250), 
        Pnt2(750, 750), 
        0.0,
        2, 
        identity_shape_core,
        false,
        nothing
    )
    for tri in floor
        push!(primitives, Primitive(tri, mat_white, nothing))
    end

    dragon_translate = Translate(Pnt3(340, 80, 275)) * RotateY(140.0) * RotateZ(-135.0) * Scale(Vec3(1.5, 1.5, 1.5))
    dragon =  parse_obj(
        "../ref/dragon1.obj",
        dragon_translate,
        false,
        false,
        nothing
    )

    for tri in dragon
        push!(primitives, Primitive(tri, mat_white, nothing))
    end

    # instantiate accelerator
    print("\nThere are " * num2str(length(primitives)) * " objects in the scene, building BVH\n")
    @time bvh = BVH(primitives)
    print("Done building BVH\n")

    # Instantiate a Filter
    filter = BoxFilter(Pnt2(.1, .1))

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
    look_from = Pnt3(278, 278, -300)
    look_at = Pnt3(278, 150, 0)
    up = Vec3(0, 1, 0)
    screen = Bounds2(Pnt2(-1, -1), Pnt2(1, 1))
    C = PerspectiveCamera(LookAt(look_from, look_at, up), screen, 0.0, 1.0, 0.0, 1e6, 40.0, film)

    # Instantiate a Sampler
    S = StratifiedSampler(parsed_args["samples-per-pixel"], parsed_args["jitter"])
    print("Using " * num2str(S.samples_per_pixel) * " samples per pixel\n")
    
    # Instantiate Scene
    print("There are " * num2str(length(lights)) * " lights in the scene\n")
    scene = Scene(lights, bvh)
    
    # Instantiate an Integrator
    I = AOIntegrator(C, S, true)

    return I, scene
end
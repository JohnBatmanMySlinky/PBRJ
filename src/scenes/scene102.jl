function make_scene102(parsed_args::Dict)::Tuple{AbstractIntegrator, Scene}
    primitives = Primitive[]
    lights = Light[]

    old_smile = jmfp("/Users/johnmyslinski/Documents/PBRJ/ref/smile3.png")
    new_smile = jmfp("/Users/johnmyslinski/Documents/PBRJ/ref/smile3_post.exr")

    # make my PNG blue!
    party_blob_fuckery!(
        old_smile,
        new_smile,
        (0.3, 0.3, 1.3)
    )

    # materials
    mat_gray = Matte(
        ConstantTexture(spectrum_from_float(0.5, 0.5, 0.5)),
        ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
        nothing
    )

    emissive_color = spectrum_from_float(0.3, 0.3, 1.3)
    Kd = MixMultTexture(
        ConstantTexture(emissive_color),
        ImageTexture(UVMapping2D(), new_smile)
    )
    mat_blob = Matte(
        Kd,
        ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
        nothing
    )

    ###############
    ### a thing ###
    ###############       

    radius = 1.0
    sphere_t = Shear(0.0, 0.0, 0.3, 0.0, 0.0, 0.0) * Scale(1.0, 1.4, 1.0) * RotateY(130.0) * RotateZ(-35.0) * RotateX(-80.0)
    sphere = Sphere(
        ShapeCore(sphere_t, Inv(sphere_t), false, false),
        radius
    )
    alight = DiffuseAreaLight(
        emissive_color,
        sphere,
        false,
        nothing,
        new_smile,
        1.0
    )
    push!(primitives, Primitive(sphere, mat_blob, alight))
    push!(lights, alight)

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

    # Instantiate a Filter
    filter = BoxFilter(Pnt2(.5, .5))

    # Instantiate a Film
    film = Film(
        Pnt2(parsed_args["image-dim"][1], parsed_args["image-dim"][2]),
        Bounds2(Pnt2(parsed_args["crop-window"][1], parsed_args["crop-window"][2]), Pnt2(parsed_args["crop-window"][3], parsed_args["crop-window"][4])),
        filter,
        1.0,
        1.0,
        parsed_args["file-name"]
    )

    # Instantiate a Camera
    look_from = Pnt3(4, 4, 4)
    look_at = Pnt3(0, radius, 0)
    up = Vec3(0, 1, 0)
    screen = Bounds2(Pnt2(-1, -1), Pnt2(1, 1))
    C = PerspectiveCamera(LookAt(look_from, look_at, up), screen, 0.0, 1.0, 0.0, 1e6, 37.0, film)

    # Instantiate a Sampler
    S = ZSobolSampler(
        parsed_args["samples-per-pixel"], 
        Pnt2(parsed_args["image-dim"][1], parsed_args["image-dim"][2]), 
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
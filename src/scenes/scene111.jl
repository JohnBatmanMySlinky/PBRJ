function make_scene111(parsed_args::Dict)::Tuple{AbstractIntegrator, Scene}
    primitives = Primitive[]
    lights = Light[]
    materials = Material[]

    mat_gray = Matte(
        "mat_gray",
        ConstantTexture(spectrum_from_float(0.5)),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_gray)

    screen = RayTracing.Bounds2(
        RayTracing.Pnt2(-100, 0),
        RayTracing.Pnt2(100, 200)
    )

    pixels = RayTracing.Bounds2i(
        RayTracing.Pnt2i(0, 0),
        RayTracing.Pnt2i(250, 250),
    )
    @assert pixels.pMin.x == pixels.pMin.y == 0.0

    file_path = "/Users/johnmyslinski/Documents/PBRJ/ref/svetlana.jpg"
    img = load(file_path)
    img = imresize(img, (pixels.pMax.x, pixels.pMax.y))
    img = reverse(img, dims=1)

    pixel_size = RayTracing.Pnt2(
        (screen.pMax.x - screen.pMin.x) / (pixels.pMax.x - pixels.pMin.x),
        (screen.pMax.y - screen.pMin.y) / (pixels.pMax.y - pixels.pMin.y)
    )
    @assert pixel_size.x == pixel_size.y

    led_size = pixel_size.x * 0.9 * 0.5

    for x in pixels.pMin.x:pixels.pMax.x - 1
        for y in pixels.pMin.y:pixels.pMax.y - 1
            t = Translate(Pnt3(
                screen.pMin.x + (x - 0.5) * pixel_size.x,
                screen.pMin.y + (y - 0.5) * pixel_size.y,
                -20.0
            ))
            sc = ShapeCore(t, Inv(t), false, false)
            s = Sphere(sc, led_size)
            mat_tmp = Matte(
                "mat_$(x)_$(y)",
                ConstantTexture(spectrum_from_float(Float64(img[y+1,x+1].r), Float64(img[y+1,x+1].g), Float64(img[y+1,x+1].b))),
                ConstantTexture(0.0),
                nothing
            )
            push!(primitives, Primitive(s, "mat_$(x)_$(y)", nothing))
            push!(materials, mat_tmp)
        end
    end

    floor = Rectangle(
        Pnt2(-500, -500),
        Pnt2(500, 500),
        0.0,
        2,
        ShapeCore(),
        false,
        nothing
    )
    for tri in floor
        push!(primitives, Primitive(tri, "mat_gray", nothing))
    end

    back_wall = Rectangle(
        Pnt2(-500, -500),
        Pnt2(500, 500),
        -50.0,
        3,
        ShapeCore(),
        false,
        nothing
    )
    for tri in back_wall
        push!(primitives, Primitive(tri, "mat_gray", nothing))
    end

    name_index = Dict(mat.name => i for (i, mat) in enumerate(materials))
    MATERIAL_REGISTRY[] = MaterialRegistry(materials, name_index)

    # instantiate accelerator
    print("\nThere are " * num2str(length(primitives)) * " objects in the scene, building BVH\n")
    @time bvh = BVH(primitives)
    print("Done building BVH\n")

    l_2_w_matrix = Mat4([-0.224951, 0.0, -0.97437, 0.0, -0.97437, 0.0, 0.224951, 0.0, 0.0, 1.0, 0.0, 8.87, 0.0, 0.0, 0.0, 1.0])
    l_2_w = Transformation(l_2_w_matrix, inv(l_2_w_matrix))
    light = InfiniteLight(
        world_bounds(bvh),
        l_2_w,
        spectrum_from_float(1.0),
        jmfp("/Users/johnmyslinski/Documents/pbrt-v3-scenes/sssdragon/textures/envmap.exr"),
        false
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
    look_from = Pnt3(30.0, 100.0, 400.0)
    look_at = Pnt3(0.0, 100.0, -20.0)
    up = Vec3(0, 1, 0)
    C = PerspectiveCamera(LookAt(look_from, look_at, up), nothing, 0.0, 1.0, 0.0, 1e6, 37.0, film)

    # Instantiate a Sampler
    S = SamplerFactory(parsed_args)
    print("Using " * num2str(S.samples_per_pixel) * " samples per pixel\n")
    
    # Instantiate Scene
    print("There are " * num2str(length(lights)) * " lights in the scene\n")
    scene = Scene(lights, bvh)
    
    # Instantiate an Integrator
    I = BDPTIntegrator(C, S, parsed_args["max-depth"])

    return I, scene
end

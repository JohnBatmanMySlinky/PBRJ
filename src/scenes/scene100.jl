function make_scene100(parsed_args::Dict)::Tuple{AbstractIntegrator, Scene}
    primitives = Primitive[]
    lights = Light[]
    materials = Material[]

    mat_gray = Matte(            
        "mat_gray",
        ConstantTexture(spectrum_from_float(0.1, 0.1, 0.1)),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_gray)

    mat_curves = Matte(            
        "mat_curves",
        ConstantTexture(spectrum_from_float(0.15, 0.21, 1.0)),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_curves)

    mat_bunny = Matte(            
        "mat_bunny",
        ConstantTexture(spectrum_from_float(0.35, 0.31, 0.3)),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_bunny)

    mat_hair = HairMaterial(
        "mat_hair",
        nothing,       # sigma_a
        ConstantTexture(spectrum_from_float(0.5, 0.5, 0.5)),         # color
        nothing,     # eumelanin
        nothing,   # pheomelanin
        nothing,           # eta
        ConstantTexture(0.5),        # beta_m
        ConstantTexture(0.5),        # beta_n
        nothing          # alpha
    )
    push!(materials, mat_hair)

    name_index = Dict(mat.name => i for (i, mat) in enumerate(materials))
    MATERIAL_REGISTRY[] = MaterialRegistry(materials, name_index)

    # curves_t = Inv(Translate(Pnt3(0,2,5))) * Translate(Pnt3(.15, -.03, 0)) * Scale(7.0, 7.0, 7.0)
    curves_t = Translate(Pnt3(.15, -.03, 0)) * Scale(7.0, 7.0, 7.0)
    fur_shape_core = ShapeCore(
        curves_t,
        Inv(curves_t),
        false,
        false
    )

    curves = parse_curves(
        jmfp("/home/jmyslinski/random_stuff/pbrt-v4-scenes/bunny-fur/geometry/bunny-fur-curves.pbrt"),
        fur_shape_core,
        0
    )
    for curve in curves
        push!(primitives, Primitive(curve, "mat_hair", nothing))
    end

    bunny_t = Translate(Pnt3(.15, -.03, 0)) * Scale(7.0, 7.0, 7.0) * Translate(Pnt3(0, -0.033, 0))
    bunny = parse_obj(
        jmfp("/home/jmyslinski/random_stuff/pbrt-v4-scenes/bunny-fur/geometry/bunnymesh.obj"),
        bunny_t,
        false,
        false,
        nothing
    )
    for tris in bunny
        for tri in tris
            push!(primitives, Primitive(tri, "mat_bunny", nothing))
        end
    end

    # ground
    ground_t = Translate(Pnt3(0, 0, -5))
    ground = BilinearPatchGenerator(
        ShapeCore(ground_t, Inv(ground_t), false, false),
        1,
        Pnt3[Pnt3(-10, 0, -10), Pnt3(10, 0, -10), Pnt3(10, 0, 10), Pnt3(-10, 0, 10)],
        Int64[1, 2, 3, 4],

        nothing, 
        nothing, 
        
        nothing,
        nothing,

        nothing
    )
    for each in ground
        push!(primitives, Primitive(each, "mat_gray", nothing))
    end

    #backstop
    blp_t = Translate(Pnt3(0, 1, 0))
    blp = BilinearPatchGenerator(
        ShapeCore(blp_t, Inv(blp_t), false, false),
        1,
        Pnt3[Pnt3(-10, 0, -2), Pnt3(10, 0, -2), Pnt3(-10, 10, -2), Pnt3(10, 10, -2)],
        Int64[1, 2, 3, 4],
        nothing, 
        nothing, 
        
        nothing,
        nothing,

        nothing
    )
    for each in blp
        push!(primitives, Primitive(each, "mat_gray", nothing))
    end
    cyl_t = Translate(Pnt3(0, 1, -1)) * Rotate(-90.0, Vec3(1, 0, 0)) * Rotate(90.0, Vec3(0, 1, 0))
    cyl = Cylindar(
        cyl_t,
        1.0,
        -10.0,
        10.0,
        90.0,
        false,
        false
    )
    push!(primitives, Primitive(cyl, "mat_gray", nothing))

        
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
        jmfp("/Users/johnmyslinski/Documents/pbrt-v3-scenes/cloud/textures/skylight-morn.exr"),
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
    look_from = Pnt3(0, 2, 5)
    look_at = Pnt3(.02, .47, 0)
    up = Vec3(0, 1, 0)
    C = PerspectiveCamera(LookAt(look_from, look_at, up), nothing, 0.0, 1.0, 0.0, 1e6, 20.0, film)

    # Instantiate a Sampler
    # S = ZSobolSampler(
    #     parsed_args["samples-per-pixel"], 
    #     Pnt2(parsed_args["image-dim"], parsed_args["image-dim"]), 
    #     Int8(2)
    # )
    S = StratifiedSampler(parsed_args["samples-per-pixel"], parsed_args["jitter"])
    print("Using " * num2str(S.samples_per_pixel) * " samples per pixel\n")

    # Instantiate Scene
    print("There are " * num2str(length(lights)) * " lights in the scene\n")
    scene = Scene(lights, bvh)

    # Instantiate an Integrator
    # I = SimpleIntegrator(C, S)
    I = BDPTIntegrator(C, S, parsed_args["max-depth"])
    return I, scene
end
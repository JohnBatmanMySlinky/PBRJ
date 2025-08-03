function make_scene99(parsed_args::Dict)::Tuple{AbstractIntegrator, Scene}
    primitives = Primitive[]
    lights = Light[]
    materials = Material[]

    mat_gray = Matte(
        "mat_gray",
        ConstantTexture(spectrum_from_float(0.6, 0.6, 0.6)),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_gray)

    mat_wax = Uber(
        "mat_wax",
        ConstantTexture(spectrum_from_float(0.639999986)),
        ConstantTexture(spectrum_from_float(0.5)),
        ConstantTexture(spectrum_from_float(0.0)),
        ConstantTexture(spectrum_from_float(0.0)),
        ConstantTexture(0.0104080001),
        nothing,
        nothing,
        ConstantTexture(1.0),
        ConstantTexture(spectrum_from_float(1.0)),
        nothing
    )
    push!(materials, mat_wax)

    mat_metal = Metal(
        "mat_metal",
        ConstantTexture(spectrum_from_sampled(jmfp("/home/jmyslinski/random_stuff/pbrt-v3-scenes/barcelona-pavilion/spds/Al.eta.spd"))),
        ConstantTexture(spectrum_from_sampled(jmfp("/home/jmyslinski/random_stuff/pbrt-v3-scenes/barcelona-pavilion/spds/Al.k.spd"))),
    )
    push!(materials, mat_metal)

    mat_black_glossy = Plastic(
        "mat_black_glossy",
        ConstantTexture(spectrum_from_float(0.02, 0.02, 0.02)),
        ConstantTexture(spectrum_from_float(0.02, 0.02, 0.02)),
        ConstantTexture(0.0104080001),
        nothing,
        nothing,
        nothing,
        true
    )
    push!(materials, mat_black_glossy)

    mat_leather = Fourier(
        "mat_leather",
        jmfp("/Users/johnmyslinski/Documents/pbrt-v3-scenes/barcelona-pavilion/bsdfs/leather.bsdf"),
        nothing
    )
    push!(materials, mat_leather)

    name_index = Dict(mat.name => i for (i, mat) in enumerate(materials))
    MATERIAL_REGISTRY[] = MaterialRegistry(materials, name_index)

    sphereamid_materials = [
        "mat_wax",
        "mat_metal",
        "mat_black_glossy",
        "mat_leather"
    ]
    sphereamid_materials_dist = Distribution1D(ones(Float64, length(sphereamid_materials)))

    base_t = RayTracing.Translate(RayTracing.Pnt3(0,0,0))
    max_depth = 4
    r = 0.5
    r_vec = Float64[r^(i-1) for i in 1:max_depth]
    spheres = RayTracing.Sphere[]
    Random.seed!(parsed_args["seed"])
    recursive_pyramid_build!(
        spheres,
        base_t,
        r_vec,
        1,
        4
    )

    for sphere in spheres
        idx, _, _ = sample_discrete(sphereamid_materials_dist, rand())
        push!(primitives, Primitive(sphere, sphereamid_materials[idx], nothing))
    end

    # The floor
    floor_transform = Translate(Pnt3(0, world_bounds(BVH(primitives)).pMin.y, 0))
    floor = Rectangle(
        Pnt2(-100, -100),
        Pnt2(100, 100),
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
    l_2_w = RotateX(10.0)
    light = InfiniteLight(
        world_bounds(bvh), 
        l_2_w, 
        spectrum_from_float(4.0, Illuminant), 
        jmfp("/Users/johnmyslinski/Documents/pbrt-v4-scenes/bunny-cloud/textures/sky.exr"),
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
    look_from = Pnt3(-10, 5, -10)
    look_at = centroid(world_bounds(bvh))
    up = Vec3(0, 1, 0)
    screen = Bounds2(Pnt2(-1, -1), Pnt2(1, 1))
    C = PerspectiveCamera(LookAt(look_from, look_at, up), screen, 0.0, 1.0, 0.0, 1e6, 15.0, film)

    # Instantiate a Sampler
    S = ZSobolSampler(
        parsed_args["samples-per-pixel"], 
        Pnt2i(parsed_args["image-dim"][1], parsed_args["image-dim"][2]), 
        Int8(2),
        parsed_args["seed"]
    )
    print("Using " * num2str(S.samples_per_pixel) * " samples per pixel\n")

    # Instantiate Scene
    print("There are " * num2str(length(lights)) * " lights in the scene\n")
    scene = Scene(lights, bvh)

    # Instantiate an Integrator
    I = BDPTIntegrator(C, S, parsed_args["max-depth"])
    return I, scene
end
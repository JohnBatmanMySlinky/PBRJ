function make_scene112(parsed_args::Dict)::Tuple{AbstractIntegrator, Scene}
    primitives = Primitive[]
    lights = Light[]
    materials = Material[]


    mats = Tuple{String, Pnt3}[
        ("mat_blue",   Pnt3(0.1216, 0.4667, 0.7059)),
        ("mat_orange", Pnt3(1.0000, 0.4980, 0.0549)),
        ("mat_green",  Pnt3(0.1725, 0.6275, 0.1725)),
        ("mat_red",    Pnt3(0.8392, 0.1529, 0.1569)),
        ("mat_purple", Pnt3(0.5804, 0.4039, 0.7412)),
        ("mat_brown",  Pnt3(0.5490, 0.3373, 0.2941)),
        ("mat_pink",   Pnt3(0.8902, 0.4667, 0.7608)),
        ("mat_gray",   Pnt3(0.4980, 0.4980, 0.4980)),
        ("mat_olive",  Pnt3(0.7373, 0.7412, 0.1333)),
        ("mat_cyan",   Pnt3(0.0902, 0.7451, 0.8118)),
        ("mat_yellow", Pnt3(1.0000, 0.8431, 0.0000)),
        ("mat_teal", Pnt3(0.1490, 0.7216, 0.6784)),
    ]
    for (mat_name, rgb) in mats
        mat_tmp = Matte(
            mat_name,
            ConstantTexture(spectrum_from_float(rgb.x, rgb.y, rgb.z)),
            ConstantTexture(0.0),
            nothing
        )
        push!(materials, mat_tmp)
    end

    # ADD IN OBJ
    transform_dict = Dict{String, ShapeCore}()
    alpha_mask_dict = Dict{String, Maybe{String}}()
    obj, group_to_idx = parse_obj_3dsmax_2011(
        jmfp("/Users/johnmyslinski/Documents/PBRJ/ref/ocean_n_boat.obj"),
        transform_dict,
        alpha_mask_dict
    )

    for (i, tris) in enumerate(obj)
        for tri in tris
            
            if group_to_idx[i] in ["# object Plane001"]
                push!(primitives, Primitive(tri, "mat_blue", nothing))

            elseif group_to_idx[i] in ["# object NGon001"]
                push!(primitives, Primitive(tri, "mat_orange", nothing))

            elseif group_to_idx[i] in ["# object NGon002"]
                push!(primitives, Primitive(tri, "mat_green", nothing))

            elseif group_to_idx[i] in ["# object Box001"]
                push!(primitives, Primitive(tri, "mat_red", nothing))

            elseif group_to_idx[i] in ["# object Line001"]
                push!(primitives, Primitive(tri, "mat_purple", nothing))

            elseif group_to_idx[i] in ["# object Cylinder001"]
                push!(primitives, Primitive(tri, "mat_brown", nothing))

            elseif group_to_idx[i] in ["# object Cylinder002"]
                push!(primitives, Primitive(tri, "mat_pink", nothing))

            elseif group_to_idx[i] in ["# object Cylinder003"]
                push!(primitives, Primitive(tri, "mat_gray", nothing))

            elseif group_to_idx[i] in ["# object Cylinder004"]
                push!(primitives, Primitive(tri, "mat_olive", nothing))

            elseif group_to_idx[i] in ["# object Cylinder005"]
                push!(primitives, Primitive(tri, "mat_cyan", nothing))

            elseif group_to_idx[i] in ["# object Box002"]
                push!(primitives, Primitive(tri, "mat_yellow", nothing))
            end
        end
    end

    # ADD IN LETTERS
    letter_idx = 0
    for (k,v) in group_to_idx
        if v == "# object Plane001"
            letter_idx = k
            break
        end
    end

    plane = obj[letter_idx]
    weights = zeros(Float64, length(plane))
    for (i, tri) in enumerate(plane)
        weights[i] = RayTracing.area(tri)
    end

    tri_sampling_dist = RayTracing.Distribution1D(weights)
    letter_sampling_dist = RayTracing.Distribution1D(ones(Float64, 26))

    N_LETTERS = 100
    LETTERS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

    for n in 1:N_LETTERS
        chose_letter = rand()
        chose_tri = rand()
        chose_p = Pnt2(rand(), rand())
        chose_rotate_x = rand()
        chose_rotate_y = rand()
        chose_rotate_z = rand()
       
        tri_idx, _, _ = sample_discrete(tri_sampling_dist, chose_tri)
        p, _, _, _ = sample(plane[tri_idx], chose_p)

        letter_sample_idx, _, _ = sample_discrete(letter_sampling_dist, chose_letter)
        letter = LETTERS[letter_sample_idx]
        # plane is 10_000 wide / ~ 50 letters wide = scale of ~ 200
        letter_t = RotateX(chose_rotate_x) * RotateY(chose_rotate_y) * RotateZ(chose_rotate_z) * Translate(p) * Scale(Vec3(200.0, 200.0, 200.0))
        # parsing in the loop is bad but I letter_t is defined within the loop :(
        # far too lazy to refactor that out
        letter_obj = parse_obj(
            jmfp("/home/jmyslinski/random_stuff/PBRJ/ref/alphabet/" * letter * ".obj"),
            letter_t, 
            false, 
            false,
            nothing
        )
        for tris in letter_obj
            for tri in tris
                push!(primitives, Primitive(tri, "mat_teal", nothing))
            end
        end
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
    look_from = Pnt3(5_000.0, -5_000.0, 2000.0)
    look_at = Pnt3(700.0, 0.0, 111.0)
    up = Vec3(0, 0, 1)
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

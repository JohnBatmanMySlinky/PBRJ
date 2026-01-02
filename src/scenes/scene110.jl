"""
     -x
     |
     |
-z ----- z
     |
     |
     x

    gggggggggggggggggg
    gggggggggggggggggg
    gggggggggggggggggg
wwwwwwwwwwwwwwwwwwwwwwwwww
        pppp
        pppp
    L
                L
       L
        C
"""




function make_scene110(parsed_args::Dict)::Tuple{AbstractIntegrator, Scene}
    primitives = Primitive[]
    lights = Light[]
    materials = Material[]

    mat_gray = Matte(
        "mat_gray",
        ConstantTexture(spectrum_from_float(0.5, 0.5, 0.5)),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_gray)

    mat_red = Matte(
        "mat_red",
        ConstantTexture(spectrum_from_float(0.9, 0.1, 0.15)),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_red)

    mat_green = Matte(
        "mat_green",
        ConstantTexture(spectrum_from_float(0.0, 0.9, 0.0)),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_green)

    mat_blue = Matte(
        "mat_blue",
        ConstantTexture(spectrum_from_float(0.0, 0.0, 0.95)),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_blue)

    mat_yellow = Matte(
        "mat_yellow",
        ConstantTexture(spectrum_from_float(0.9, 0.9, 0.0)),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_yellow)

    mat_pink = Matte(
        "mat_pink",
        ConstantTexture(spectrum_from_float(0.1, 0.4, 0.7)),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_pink)

    mat_purple = Matte(
        "mat_purple",
        ConstantTexture(spectrum_from_float(0.5, 0.0, 0.5)),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_purple)

    transform_dict = Dict{String, ShapeCore}()
    transform_dict["# object Ground"] = ShapeCore(Translate(Pnt3(0, -10, 0)), Inv(Translate(Pnt3(0, -10, 0))), false, false)
    transform_dict["# object Pillars"] = ShapeCore(Translate(Pnt3(0, -5, 0)), Inv(Translate(Pnt3(0, -5, 0))), false, false)

    alpha_mask_dict = Dict{String, Maybe{String}}()

    obj, group_to_idx = parse_obj_3dsmax_2011(
        jmfp("/Users/johnmyslinski/Documents/PBRJ/ref/floating_lanterns/autobackup02_3.obj"),
        transform_dict,
        alpha_mask_dict
    )

    for (i, tris) in enumerate(obj)
        for tri in tris
            if group_to_idx[i] in ["# object Lantern", "# object Lantern_Base"]
                push!(primitives, Primitive(tri, "mat_red", nothing))

            elseif group_to_idx[i] in ["# object Lantern001", "# object Lantern_Base001"]
                push!(primitives, Primitive(tri, "mat_green", nothing))

            elseif group_to_idx[i] in ["# object Lantern002", "# object Lantern_Base002"]
                push!(primitives, Primitive(tri, "mat_blue", nothing))

            elseif group_to_idx[i] in ["# object Lantern003", "# object Lantern_Base003"]
                push!(primitives, Primitive(tri, "mat_yellow", nothing))

            elseif group_to_idx[i] in ["# object Lantern004", "# object Lantern_Base004"]
                push!(primitives, Primitive(tri, "mat_pink", nothing))

            elseif group_to_idx[i] in ["# object Lantern005", "# object Lantern_Base005"]
                push!(primitives, Primitive(tri, "mat_purple", nothing))

            else
                push!(primitives, Primitive(tri, "mat_gray", nothing))
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
    look_from = Pnt3(475.0, 95.0, 90.0)
    look_at = Pnt3(-200.0, 55.0, 90.0)
    up = Vec3(0, 1, 0)
    C = PerspectiveCamera(LookAt(look_from, look_at, up) * Scale(-1.0, 1.0, 1.0), nothing, 0.0, 1.0, 0.0, 1e6, 59.0, film)

    # Instantiate a Sampler
    S = SamplerFactory(parsed_args)
    print("Using " * num2str(S.samples_per_pixel) * " samples per pixel\n")
    
    # Instantiate Scene
    print("There are " * num2str(length(lights)) * " lights in the scene\n")
    scene = Scene(lights, bvh)
    
    # Instantiate an Integrator
    I = VolPathIntegratorv3(C, S, parsed_args["max-depth"])

    return I, scene
end

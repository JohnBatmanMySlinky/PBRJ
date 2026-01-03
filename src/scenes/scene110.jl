"""
     -x
     |
     |
z ------ -z
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

    mat_lantern = Matte(
        "mat_lantern",
        ImageTexture(
            UVMapping2D(),
            jmfp("/Users/johnmyslinski/Documents/PBRJ/ref/floating_lanterns/materials/lanterns/lantern diffuse.jpg"),
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_lantern)

    mat_lantern_base = Matte(
        "mat_lantern_base",
        ConstantTexture(spectrum_from_float(0.59, 0.3, 0.0))
    )
    push!(materials, mat_lantern_base)

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
        ConstantTexture(spectrum_from_float(1.0, 0.4, 0.7)),
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

    mat_white = Matte(
        "mat_white",
        ConstantTexture(spectrum_from_float(1.0, 1.0, 1.0)),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_white)

    mat_uv = Matte(
        "mat_uv",
        UVTexture(spectrum_from_float(1.0), UVMapping2D()),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_uv)

    mat_water = Mirror(
        "mat_water",
        ConstantTexture(spectrum_from_float(1.0, 1.0, 1.0)),
        ImageTexture(
            UVMapping2D(),
            jmfp("/Users/johnmyslinski/Documents/PBRJ/ref/floating_lanterns/water_noise_map.jpg"),
            true   
        )
    )
    push!(materials, mat_water)

    transform_dict = Dict{String, ShapeCore}()
    tmp = Scale(1.0, 1.2, 1.0) * Translate(Pnt3(0, -3, 0))
    transform_dict["# object Ground"] = ShapeCore(tmp, Inv(tmp), false, false)
    tmp = Translate(Pnt3(0, -5, 0))
    transform_dict["# object Pillars"] = ShapeCore(tmp, Inv(tmp), false, false)
    tmp = Translate(Pnt3(48.958849999999984, -55.12375, 0.2385500000000036))
    transform_dict["# object Lantern_Base004"] = ShapeCore(tmp, Inv(tmp), false, false)
    tmp = Translate(Pnt3(20, 0, -40))
    transform_dict["# object Lantern005"] = ShapeCore(tmp, Inv(tmp), false, false)
    transform_dict["# object Lantern_Base005"] = ShapeCore(tmp, Inv(tmp), false, false)

    transform_dict["# object Water"] = ShapeCore(Translate(Pnt3(0, 0, 0)), Inv(Translate(Pnt3(0, 0, 0))), false, false)

    alpha_mask_dict = Dict{String, Maybe{String}}()

    obj, group_to_idx = parse_obj_3dsmax_2011(
        jmfp("/Users/johnmyslinski/Documents/PBRJ/ref/floating_lanterns/autobackup02_3.obj"),
        transform_dict,
        alpha_mask_dict
    )

    for (i, tris) in enumerate(obj)
        for tri in tris
            
            if group_to_idx[i] in ["# object Lantern_Base", "# object Lantern_Base001", "# object Lantern_Base002", "# object Lantern_Base003", "# object Lantern_Base004", "# object Lantern_Base005"]
                push!(primitives, Primitive(tri, "mat_lantern_base", nothing))

            elseif group_to_idx[i] in []
                push!(primitives, Primitive(tri, "mat_red", nothing))

            elseif group_to_idx[i] in ["# object Lantern", "# object Lantern001", "# object Lantern002","# object Lantern003", "# object Lantern004", "# object Lantern005",]
                alight = DiffuseAreaLight(
                    spectrum_from_float(0.0),
                    tri,
                    false,
                    nothing,
                    jmfp("/Users/johnmyslinski/Documents/PBRJ/ref/floating_lanterns/materials/lanterns/lantern diffuse.jpg"),
                    0.5   
                )
                push!(primitives, Primitive(tri, "mat_lantern", alight))
                push!(lights, alight)

            elseif group_to_idx[i] in [ "# object Walkpath"]
                push!(primitives, Primitive(tri, "mat_blue", nothing))

            elseif group_to_idx[i] in ["# object Water"]
                push!(primitives, Primitive(tri, "mat_water", nothing))

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

    l_2_w = Rotate(-10.0, Vec3(0, 0, 1)) * Rotate(-140.0, Vec3(0, 1, 0)) * Rotate(-85.0, Vec3(1, 0, 0))
    light = InfiniteLight(
        world_bounds(bvh),
        l_2_w,
        spectrum_from_float(0.5),
        jmfp("/Users/johnmyslinski/Documents/pbrt-v3-scenes/barcelona-pavilion/textures/night.exr"),
        false
    )
    push!(lights, light)

    # l_2_w_matrix = Mat4([-0.224951, 0.0, -0.97437, 0.0, -0.97437, 0.0, 0.224951, 0.0, 0.0, 1.0, 0.0, 8.87, 0.0, 0.0, 0.0, 1.0])
    # l_2_w = Transformation(l_2_w_matrix, inv(l_2_w_matrix))
    # light = InfiniteLight(
    #     world_bounds(bvh),
    #     l_2_w,
    #     spectrum_from_float(1.0),
    #     jmfp("/Users/johnmyslinski/Documents/pbrt-v3-scenes/sssdragon/textures/envmap.exr"),
    #     false
    # )
    # push!(lights, light)

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
    look_from = Pnt3(475.0, 70.0, 90.0)
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
    I = BDPTIntegrator(C, S, parsed_args["max-depth"])

    return I, scene
end

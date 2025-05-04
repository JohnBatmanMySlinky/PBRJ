function make_scene17(parsed_args::Dict)::Tuple{AbstractIntegrator, Scene}
    primitives = Primitive[]
    lights = Light[]

    # MATERIALS
    mat_gray = Matte(
        ConstantTexture(spectrum_from_float(.9, .9, .795)),
        ConstantTexture(0.0),
        nothing
    )
    # mat_water = Glass(
    #     ConstantTexture(spectrum_from_float(1.0)),
    #     ConstantTexture(spectrum_from_float(1.0)),
    #     ConstantTexture(0.0),
    #     ConstantTexture(0.0),
    #     ConstantTexture(1.5),
    #     ImageTexture(
    #         UVMapping2D(), 
    #         jmfp("/Users/johnmyslinski/Documents/pbrt-v3-scenes/barcelona-pavilion/textures/water-raindrop.png"), 
    #         true,
    #         0,
    #         false,
    #         8.0,
    #         Int8(1),
    #         .005,
    #         false
    #     ),
    #     true
    # )
    mat_pebble_ground = Uber(
        ImageTexture(
            # 800 x 590
            UVMapping2D(1.0, 1.0, 0.0, 0.0), 
            jmfp("/Users/johnmyslinski/Documents/pbrt-v3-scenes/barcelona-pavilion/textures/rocks.png"),
            # jmfp("/Users/johnmyslinski/Documents/PBRJ/src/notebooks/colorful_grid_seed_42_5x9.png"),
            false
        ),
        ConstantTexture(spectrum_from_float(0.5)),
        ConstantTexture(spectrum_from_float(0.0)),
        ConstantTexture(spectrum_from_float(0.0)),
        ConstantTexture(0.0104080001),
        nothing,
        nothing,
        ConstantTexture(1.0),
        ConstantTexture(spectrum_from_float(1.0)),
        nothing,
        true
    )
    # @assert false
    # mat_pavet = Substrate(
    #     ImageTexture(
    #         UVMapping2D(), 
    #         jmfp("/Users/johnmyslinski/Documents/pbrt-v3-scenes/barcelona-pavilion/textures/Mies-BCN_M081.png"), 
    #         false,
    #         0,
    #         false,
    #         8.0,
    #         Int8(1),
    #         0.639999986,
    #         false
    #     ),
    #     ConstantTexture(spectrum_from_float(0.1)),
    #     ConstantTexture(.1),
    #     ConstantTexture(.1),
    #     ImageTexture(
    #         UVMapping2D(), 
    #         jmfp("/Users/johnmyslinski/Documents/pbrt-v3-scenes/barcelona-pavilion/textures/Mies-BCN_M081bump.png"), 
    #         true
    #     ),
    #     true
    # )
    # mat_concrete = Uber(
    #     ImageTexture(
    #         UVMapping2D(), 
    #         jmfp("/Users/johnmyslinski/Documents/pbrt-v3-scenes/barcelona-pavilion/textures/Mies-BCN_M121.png"), 
    #         false,
    #         0,
    #         false,
    #         8.0,
    #         Int8(1),
    #         0.639999986,
    #         false
    #     ),
    #     ConstantTexture(spectrum_from_float(0.5)),
    #     ConstantTexture(spectrum_from_float(0.0)),
    #     ConstantTexture(spectrum_from_float(0.0)),
    #     ConstantTexture(0.0104080001),
    #     nothing,
    #     nothing,
    #     ConstantTexture(1.0),
    #     ConstantTexture(spectrum_from_float(1.0)),
    #     nothing,
    #     true
    # )
    # mat_wood = Substrate(
    #     ImageTexture(
    #         UVMapping2D(), # JOHN SCALE 
    #         jmfp("/Users/johnmyslinski/Documents/pbrt-v3-scenes/barcelona-pavilion/textures/wood.png"), 
    #         false
    #     ),
    #     ConstantTexture(spectrum_from_float(.1)),
    #     ConstantTexture(.1),
    #     ConstantTexture(.1),
    #     nothing,
    #     true
    # )
    # mat_grass = Uber(
    #     ImageTexture(
    #         UVMapping2D(), 
    #         jmfp("/Users/johnmyslinski/Documents/pbrt-v3-scenes/barcelona-pavilion/textures/grass_mid_seamless.png"), 
    #         false,
    #         0,
    #         false,
    #         8.0,
    #         Int8(1),
    #         0.3,
    #         false
    #     ),
    #     ConstantTexture(spectrum_from_float(0.5)),
    #     ConstantTexture(spectrum_from_float(0.0)),
    #     ConstantTexture(spectrum_from_float(0.0)),
    #     ConstantTexture(0.1),
    #     nothing,
    #     nothing,
    #     ConstantTexture(1.0),
    #     ConstantTexture(spectrum_from_float(1.0)),
    #     nothing
    # )
    # mat_wax = Uber(
    #     ConstantTexture(spectrum_from_float(0.639999986)),
    #     ConstantTexture(spectrum_from_float(0.5)),
    #     ConstantTexture(spectrum_from_float(0.0)),
    #     ConstantTexture(spectrum_from_float(0.0)),
    #     ConstantTexture(0.0104080001),
    #     nothing,
    #     nothing,
    #     ConstantTexture(1.0),
    #     ConstantTexture(spectrum_from_float(1.0)),
    #     nothing
    # )
    # mat_metal = Metal(
    #     ConstantTexture(spectrum_from_sampled(jmfp("/home/jmyslinski/random_stuff/pbrt-v3-scenes/barcelona-pavilion/spds/Al.eta.spd"))),
    #     ConstantTexture(spectrum_from_sampled(jmfp("/home/jmyslinski/random_stuff/pbrt-v3-scenes/barcelona-pavilion/spds/Al.k.spd"))),
    # )

    mat_dict = Dict{String, Material}()

    # 1
    # mat_dict["mesh_00002.obj"] = mat_water

    #2
    mat_dict["mesh_00048.obj"] = mat_pebble_ground

    # 2 + 19 = 21
    # mat_dict["mesh_00001.obj"] = mat_pavet
    # mat_dict["mesh_00031.obj"] = mat_pavet
    # mat_dict["mesh_00032.obj"] = mat_pavet
    # mat_dict["mesh_00033.obj"] = mat_pavet
    # mat_dict["mesh_00034.obj"] = mat_pavet
    # mat_dict["mesh_00035.obj"] = mat_pavet
    # mat_dict["mesh_00036.obj"] = mat_pavet
    # mat_dict["mesh_00037.obj"] = mat_pavet
    # mat_dict["mesh_00038.obj"] = mat_pavet
    # mat_dict["mesh_00039.obj"] = mat_pavet
    # mat_dict["mesh_00040.obj"] = mat_pavet
    # mat_dict["mesh_00041.obj"] = mat_pavet
    # mat_dict["mesh_00042.obj"] = mat_pavet
    # mat_dict["mesh_00043.obj"] = mat_pavet
    # mat_dict["mesh_00044.obj"] = mat_pavet
    # mat_dict["mesh_00045.obj"] = mat_pavet
    # mat_dict["mesh_00046.obj"] = mat_pavet
    # mat_dict["mesh_00047.obj"] = mat_pavet
    # mat_dict["mesh_00052.obj"] = mat_pavet

    # 21 + 18 = 39
    # mat_dict["mesh_00049.obj"] = mat_concrete
    # mat_dict["mesh_00050.obj"] = mat_concrete
    # mat_dict["mesh_00051.obj"] = mat_concrete
    # mat_dict["mesh_00074.obj"] = mat_concrete
    # mat_dict["mesh_00075.obj"] = mat_concrete
    # mat_dict["mesh_00076.obj"] = mat_concrete
    # mat_dict["mesh_00077.obj"] = mat_concrete
    # mat_dict["mesh_00078.obj"] = mat_concrete
    # mat_dict["mesh_00079.obj"] = mat_concrete
    # mat_dict["mesh_00080.obj"] = mat_concrete
    # mat_dict["mesh_00081.obj"] = mat_concrete
    # mat_dict["mesh_00082.obj"] = mat_concrete
    # mat_dict["mesh_00083.obj"] = mat_concrete
    # mat_dict["mesh_00084.obj"] = mat_concrete
    # mat_dict["mesh_00085.obj"] = mat_concrete
    # mat_dict["mesh_00086.obj"] = mat_concrete
    # mat_dict["mesh_00087.obj"] = mat_concrete
    # mat_dict["mesh_00088.obj"] = mat_concrete

    # 39 + 12 = 51
    # mat_dict["mesh_00007.obj"] = mat_wood
    # mat_dict["mesh_00008.obj"] = mat_wood
    # mat_dict["mesh_00009.obj"] = mat_wood
    # mat_dict["mesh_00010.obj"] = mat_wood
    # mat_dict["mesh_00011.obj"] = mat_wood
    # mat_dict["mesh_00012.obj"] = mat_wood
    # mat_dict["mesh_00013.obj"] = mat_wood
    # mat_dict["mesh_00014.obj"] = mat_wood
    # mat_dict["mesh_00019.obj"] = mat_wood
    # mat_dict["mesh_00020.obj"] = mat_wood
    # mat_dict["mesh_00025.obj"] = mat_wood
    # mat_dict["mesh_00026.obj"] = mat_wood

    # 52
    # mat_dict["mesh_00114.obj"] = mat_grass

    # 52 + 6 = 58
    # mat_dict["mesh_00004.obj"] = mat_wax
    # mat_dict["mesh_00006.obj"] = mat_wax
    # mat_dict["mesh_00016.obj"] = mat_wax
    # mat_dict["mesh_00018.obj"] = mat_wax
    # mat_dict["mesh_00022.obj"] = mat_wax
    # mat_dict["mesh_00024.obj"] = mat_wax

    # 58 + 21 = 79
    # mat_dict["mesh_00027.obj"] = mat_metal
    # mat_dict["mesh_00053.obj"] = mat_metal
    # mat_dict["mesh_00054.obj"] = mat_metal
    # mat_dict["mesh_00055.obj"] = mat_metal
    # mat_dict["mesh_00056.obj"] = mat_metal
    # mat_dict["mesh_00057.obj"] = mat_metal
    # mat_dict["mesh_00063.obj"] = mat_metal
    # mat_dict["mesh_00064.obj"] = mat_metal
    # mat_dict["mesh_00065.obj"] = mat_metal
    # mat_dict["mesh_00066.obj"] = mat_metal
    # mat_dict["mesh_00067.obj"] = mat_metal
    # mat_dict["mesh_00068.obj"] = mat_metal
    # mat_dict["mesh_00069.obj"] = mat_metal
    # mat_dict["mesh_00070.obj"] = mat_metal
    # mat_dict["mesh_00071.obj"] = mat_metal
    # mat_dict["mesh_00073.obj"] = mat_metal
    # mat_dict["mesh_00091.obj"] = mat_metal
    # mat_dict["mesh_00098.obj"] = mat_metal
    # mat_dict["mesh_00102.obj"] = mat_metal
    # mat_dict["mesh_00106.obj"] = mat_metal
    # mat_dict["mesh_00110.obj"] = mat_metal

    commented_out = ["mesh_00113.obj", "mesh_00112.obj", "mesh_00002.obj"]
    commented_in = ["mesh_00048.obj"]

    dirpath = "/Users/johnmyslinski/Documents/pbrt-v3-scenes/barcelona-pavilion/geometry/"
    objs = String[]
    for (_, _, files) in walkdir(dirpath)
        # LAZILY ignoring nested folders
        for file in files
            if endswith(file, ".obj")
                push!(objs, file)
            end
        end
    end
    for obj_file in objs
        # if !(obj_file in commented_out)
        if obj_file in commented_in
            obj_path = joinpath(dirpath, obj_file)
            objects = parse_obj(
                obj_path,
                Translate(Pnt3(0,0,0)),
                false,
                false,
                nothing
            )
            for object in objects
                for mesh in object
                    if obj_file in keys(mat_dict)
                        tmp_mat = mat_dict[obj_file]
                    else
                        tmp_mat = mat_gray
                    end
                    push!(primitives, Primitive(mesh, tmp_mat, nothing))
                end
            end
        end
    end

    # instantiate accelerator
    print("\nThere are " * num2str(length(primitives)) * " objects in the scene, building BVH\n")
    @time bvh = BVH(primitives)
    print("Done building BVH\n")

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
    
    light_t = Rotate(-10.0, Vec3(0,0,1)) * Rotate(-160.0, Vec3(0,1,0)) * Rotate(-90.0, Vec3(1,0,0))
    light = InfiniteLight(
        world_bounds(bvh),
        light_t,
        spectrum_from_float(1.0),
        "/Users/johnmyslinski/Documents/pbrt-v3-scenes/barcelona-pavilion/textures/sky.exr",
        false
    )
    push!(lights, light)

    # Instantiate a Camera
    # pre-rotate X
    # positive Z is up
    # positive -X is from pool to house
    # positive Y is side to side of pool

    # post rotate X
    # z = side to side pool
    # y is up and down
    # x is pool to house. +x is away from house
    look_from = Pnt3(20, 3, -10) 
    look_at = Pnt3(0, 0, 0)
    up = Vec3(0, 1, 0)
    screen = Bounds2(Pnt2(-1, -1), Pnt2(1, 1))
    C = PerspectiveCamera(RotateX(90.0) * LookAt(look_from, look_at, up), screen, 0.0, 1.0, 0.0, 1e6, 45.0, film)

    # Instantiate a Sampler
    S = ZSobolSampler(parsed_args["samples-per-pixel"], film.full_resolution, Int8(2))
    # S = StratifiedSampler(parsed_args["samples-per-pixel"], parsed_args["jitter"])
    print("Using " * num2str(S.samples_per_pixel) * " samples per pixel\n")
    
    # Instantiate Scene
    print("There are " * num2str(length(lights)) * " lights in the scene\n")
    scene = Scene(lights, bvh)
    
    # Instantiate an Integrator
    I = BDPTIntegrator(C, S, parsed_args["max-depth"])
    return I, scene
end
function make_scene17(parsed_args::Dict)::Tuple{AbstractIntegrator, Scene}
    primitives = Primitive[]
    lights = Light[]

    # MATERIALS
    # mat_gray = Matte(
    #     ConstantTexture(spectrum_from_float(.9, .9, .795)),
    #     ConstantTexture(0.0),
    #     nothing
    # )
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
    #         Int8(0),
    #         .005,
    #         false
    #     ),
    #     true
    # )
    # mat_pebble_ground = Uber(
    #     ImageTexture(
    #         UVMapping2D(), 
    #         jmfp("/Users/johnmyslinski/Documents/pbrt-v3-scenes/barcelona-pavilion/textures/rocks.png"),
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
    # mat_pavet = Substrate(
    #     ImageTexture(
    #         UVMapping2D(), 
    #         jmfp("/Users/johnmyslinski/Documents/pbrt-v3-scenes/barcelona-pavilion/textures/Mies-BCN_M081.png"), 
    #         false,
    #         0,
    #         false,
    #         8.0,
    #         Int8(0),
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
    #         Int8(0),
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
    #         Int8(0),
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
    # mat_glass_architectural = Glass()
    # mat_black_glossy = Plastic(
    #     ConstantTexture(spectrum_from_float(0.02, 0.02, 0.02)),
    #     ConstantTexture(spectrum_from_float(0.02, 0.02, 0.02)),
    #     ConstantTexture(0.0104080001),
    #     nothing,
    #     nothing,
    #     nothing,
    #     true
    # )
    # mat_white_mat = Matte(
    #     ConstantTexture(spectrum_from_float(0.6, 0.6, 0.6)),
    #     ConstantTexture(20.0),
    #     nothing
    # )
    # mat_marble = Substrate(
    #     ImageTexture(
    #         UVMapping2D(),
    #         jmfp("/Users/johnmyslinski/Documents/pbrt-v3-scenes/barcelona-pavilion/textures/Mies-BCN_M01.png"), 
    #         false
    #     ),
    #     ConstantTexture(spectrum_from_float(0.2, 0.2, 0.2)),
    #     ConstantTexture(0.001),
    #     ConstantTexture(0.001),
    #     nothing,
    #     true
    # )
    # mat_concrete_mies_bcn_m121 = Uber(
    #     ImageTexture(
    #         UVMapping2D(), 
    #         jmfp("/Users/johnmyslinski/Documents/pbrt-v3-scenes/barcelona-pavilion/textures/Mies-BCN_M121.png"), 
    #         false,
    #         0,
    #         false,
    #         8.0,
    #         Int8(0),
    #         0.639999986,
    #         false
    #     ),
    #     ConstantTexture(spectrum_from_float(0.5, 0.5, 0.5)),
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
    # mat_marmol_verde = Substrate(
    #     ImageTexture(
    #         UVMapping2D(), 
    #         jmfp("/Users/johnmyslinski/Documents/pbrt-v3-scenes/barcelona-pavilion/textures/Mies-BCN_M11.png"), 
    #         false,
    #     ),
    #     ConstantTexture(spectrum_from_float(0.2, 0.2, 0.2)),
    #     ConstantTexture(0.001),
    #     ConstantTexture(0.001),
    #     nothing,
    #     true
    # )
    # mat_caulk = Matte(
    #     ConstantTexture(spectrum_from_float(0.4, 0.4, 0.4)),
    #     ConstantTexture(20.0),
    #     nothing
    # )
    # mat_material = Uber(
    #     ConstantTexture(spectrum_from_float(0.639999986, 0.639999986, 0.639999986)),
    #     ConstantTexture(spectrum_from_float(0.5, 0.5, 0.5)),
    #     ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
    #     ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
    #     ConstantTexture(0.0104080001),
    #     nothing,
    #     nothing,
    #     ConstantTexture(1.0),
    #     ConstantTexture(spectrum_from_float(1.0, 1.0, 1.0)),
    #     nothing,
    #     true
    # )
    mat_leather = Fourier(
        jmfp("/Users/johnmyslinski/Documents/pbrt-v3-scenes/barcelona-pavilion/bsdfs/leather.bsdf"),
        nothing
    )

    mat_dict = Dict{String, Material}()

    # 1
    # mat_dict["mesh_00002_ascii.obj"] = mat_water

    #2
    mat_dict["mesh_00048_ascii.obj"] = mat_leather # mat_pebble_ground

    # 2 + 19 = 21
    # mat_dict["mesh_00001_ascii.obj"] = mat_pavet
    # mat_dict["mesh_00031_ascii.obj"] = mat_pavet
    # mat_dict["mesh_00032_ascii.obj"] = mat_pavet
    # mat_dict["mesh_00033_ascii.obj"] = mat_pavet
    # mat_dict["mesh_00034_ascii.obj"] = mat_pavet
    # mat_dict["mesh_00035_ascii.obj"] = mat_pavet
    # mat_dict["mesh_00036_ascii.obj"] = mat_pavet
    # mat_dict["mesh_00037_ascii.obj"] = mat_pavet
    # mat_dict["mesh_00038_ascii.obj"] = mat_pavet
    # mat_dict["mesh_00039_ascii.obj"] = mat_pavet
    # mat_dict["mesh_00040_ascii.obj"] = mat_pavet
    # mat_dict["mesh_00041_ascii.obj"] = mat_pavet
    # mat_dict["mesh_00042_ascii.obj"] = mat_pavet
    # mat_dict["mesh_00043_ascii.obj"] = mat_pavet
    # mat_dict["mesh_00044_ascii.obj"] = mat_pavet
    # mat_dict["mesh_00045_ascii.obj"] = mat_pavet
    # mat_dict["mesh_00046_ascii.obj"] = mat_pavet
    # mat_dict["mesh_00047_ascii.obj"] = mat_pavet
    # mat_dict["mesh_00052_ascii.obj"] = mat_pavet

    # 21 + 18 = 39
    # mat_dict["mesh_00049_ascii.obj"] = mat_concrete
    # mat_dict["mesh_00050_ascii.obj"] = mat_concrete
    # mat_dict["mesh_00051_ascii.obj"] = mat_concrete
    # mat_dict["mesh_00074_ascii.obj"] = mat_concrete
    # mat_dict["mesh_00075_ascii.obj"] = mat_concrete
    # mat_dict["mesh_00076_ascii.obj"] = mat_concrete
    # mat_dict["mesh_00077_ascii.obj"] = mat_concrete
    # mat_dict["mesh_00078_ascii.obj"] = mat_concrete
    # mat_dict["mesh_00079_ascii.obj"] = mat_concrete
    # mat_dict["mesh_00080_ascii.obj"] = mat_concrete
    # mat_dict["mesh_00081_ascii.obj"] = mat_concrete
    # mat_dict["mesh_00082_ascii.obj"] = mat_concrete
    # mat_dict["mesh_00083_ascii.obj"] = mat_concrete
    # mat_dict["mesh_00084_ascii.obj"] = mat_concrete
    # mat_dict["mesh_00085_ascii.obj"] = mat_concrete
    # mat_dict["mesh_00086_ascii.obj"] = mat_concrete
    # mat_dict["mesh_00087_ascii.obj"] = mat_concrete
    # mat_dict["mesh_00088_ascii.obj"] = mat_concrete

    # 39 + 12 = 51
    # mat_dict["mesh_00007_ascii.obj"] = mat_wood
    # mat_dict["mesh_00008_ascii.obj"] = mat_wood
    # mat_dict["mesh_00009_ascii.obj"] = mat_wood
    # mat_dict["mesh_00010_ascii.obj"] = mat_wood
    # mat_dict["mesh_00011_ascii.obj"] = mat_wood
    # mat_dict["mesh_00012_ascii.obj"] = mat_wood
    # mat_dict["mesh_00013_ascii.obj"] = mat_wood
    # mat_dict["mesh_00014_ascii.obj"] = mat_wood
    # mat_dict["mesh_00019_ascii.obj"] = mat_wood
    # mat_dict["mesh_00020_ascii.obj"] = mat_wood
    # mat_dict["mesh_00025_ascii.obj"] = mat_wood
    # mat_dict["mesh_00026_ascii.obj"] = mat_wood

    # 52
    # mat_dict["mesh_00114_ascii.obj"] = mat_grass

    # 52 + 6 = 58
    # mat_dict["mesh_00004_ascii.obj"] = mat_wax
    # mat_dict["mesh_00006_ascii.obj"] = mat_wax
    # mat_dict["mesh_00016_ascii.obj"] = mat_wax
    # mat_dict["mesh_00018_ascii.obj"] = mat_wax
    # mat_dict["mesh_00022_ascii.obj"] = mat_wax
    # mat_dict["mesh_00024_ascii.obj"] = mat_wax

    # 58 + 21 = 79
    # mat_dict["mesh_00027_ascii.obj"] = mat_metal
    # mat_dict["mesh_00053_ascii.obj"] = mat_metal
    # mat_dict["mesh_00054_ascii.obj"] = mat_metal
    # mat_dict["mesh_00055_ascii.obj"] = mat_metal
    # mat_dict["mesh_00056_ascii.obj"] = mat_metal
    # mat_dict["mesh_00057_ascii.obj"] = mat_metal
    # mat_dict["mesh_00063_ascii.obj"] = mat_metal
    # mat_dict["mesh_00064_ascii.obj"] = mat_metal
    # mat_dict["mesh_00065_ascii.obj"] = mat_metal
    # mat_dict["mesh_00066_ascii.obj"] = mat_metal
    # mat_dict["mesh_00067_ascii.obj"] = mat_metal
    # mat_dict["mesh_00068_ascii.obj"] = mat_metal
    # mat_dict["mesh_00069_ascii.obj"] = mat_metal
    # mat_dict["mesh_00070_ascii.obj"] = mat_metal
    # mat_dict["mesh_00071_ascii.obj"] = mat_metal
    # mat_dict["mesh_00073_ascii.obj"] = mat_metal
    # mat_dict["mesh_00091_ascii.obj"] = mat_metal
    # mat_dict["mesh_00098_ascii.obj"] = mat_metal
    # mat_dict["mesh_00102_ascii.obj"] = mat_metal
    # mat_dict["mesh_00106_ascii.obj"] = mat_metal
    # mat_dict["mesh_00110_ascii.obj"] = mat_metal

    # 79 + 6 = 85
    # mat_dict["mesh_00028_ascii.obj"] = mat_glass_architectural
    # mat_dict["mesh_00058_ascii.obj"] = mat_glass_architectural
    # mat_dict["mesh_00059_ascii.obj"] = mat_glass_architectural
    # mat_dict["mesh_00060_ascii.obj"] = mat_glass_architectural
    # mat_dict["mesh_00061_ascii.obj"] = mat_glass_architectural
    # mat_dict["mesh_00062_ascii.obj"] = mat_glass_architectural

    # 85 + 2 = 87
    # mat_dict["mesh_00029_ascii.obj"] = mat_black_glossy
    # mat_dict["mesh_00089_ascii.obj"] = mat_black_glossy

    # 87 + 2 = 89
    # mat_dict["mesh_00030_ascii.obj"] = mat_white_mat
    # mat_dict["mesh_00090_ascii.obj"] = mat_white_mat

    # 89 + 1 = 90
    # mat_dict["mesh_00072_ascii.obj"] = mat_marble

    # 90 + 15 = 105
    # mat_dict["mesh_00074_ascii.obj"] = mat_concrete_mies_bcn_m121
    # mat_dict["mesh_00075_ascii.obj"] = mat_concrete_mies_bcn_m121
    # mat_dict["mesh_00076_ascii.obj"] = mat_concrete_mies_bcn_m121
    # mat_dict["mesh_00077_ascii.obj"] = mat_concrete_mies_bcn_m121
    # mat_dict["mesh_00078_ascii.obj"] = mat_concrete_mies_bcn_m121
    # mat_dict["mesh_00079_ascii.obj"] = mat_concrete_mies_bcn_m121
    # mat_dict["mesh_00080_ascii.obj"] = mat_concrete_mies_bcn_m121
    # mat_dict["mesh_00081_ascii.obj"] = mat_concrete_mies_bcn_m121
    # mat_dict["mesh_00082_ascii.obj"] = mat_concrete_mies_bcn_m121
    # mat_dict["mesh_00083_ascii.obj"] = mat_concrete_mies_bcn_m121
    # mat_dict["mesh_00084_ascii.obj"] = mat_concrete_mies_bcn_m121
    # mat_dict["mesh_00085_ascii.obj"] = mat_concrete_mies_bcn_m121
    # mat_dict["mesh_00086_ascii.obj"] = mat_concrete_mies_bcn_m121
    # mat_dict["mesh_00087_ascii.obj"] = mat_concrete_mies_bcn_m121
    # mat_dict["mesh_00088_ascii.obj"] = mat_concrete_mies_bcn_m121

    # 105 + 2 = 107
    # mat_dict["mesh_00092_ascii.obj"] = mat_marmol_verde
    # mat_dict["mesh_00093_ascii.obj"] = mat_marmol_verde

    # 107 + 1 = 108
    # mat_dict["mesh_00094_ascii.obj"] = mat_caulk

    # 108 + 1 = 109
    # mat_dict["mesh_00095_ascii.obj"] = mat_material

    # 109 + 12 = 121
    # JOHN HACK SUPPOSED TO BE LEATHER
    # mat_dict["mesh_00096_ascii.obj"] = mat_leather
    # mat_dict["mesh_00097_ascii.obj"] = mat_leather
    # mat_dict["mesh_00099_ascii.obj"] = mat_leather
    # mat_dict["mesh_00100_ascii.obj"] = mat_leather
    # mat_dict["mesh_00101_ascii.obj"] = mat_leather
    # mat_dict["mesh_00103_ascii.obj"] = mat_leather
    # mat_dict["mesh_00104_ascii.obj"] = mat_leather
    # mat_dict["mesh_00105_ascii.obj"] = mat_leather
    # mat_dict["mesh_00107_ascii.obj"] = mat_leather
    # mat_dict["mesh_00108_ascii.obj"] = mat_leather
    # mat_dict["mesh_00109_ascii.obj"] = mat_leather
    # mat_dict["mesh_00111_ascii.obj"] = mat_leather


    commented_out = ["mesh_00113_ascii.obj", "mesh_00112_ascii.obj"]
        commented_in = ["mesh_00048_ascii.obj"]

    dirpath = jmfp("/Users/johnmyslinski/Documents/pbrt-v3-scenes/barcelona-pavilion/geometry/")
    objs = String[]
    for (_, _, files) in walkdir(dirpath)
        # LAZILY ignoring nested folders
        for file in files
            if endswith(file, "_ascii.obj")
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
        jmfp("/Users/johnmyslinski/Documents/pbrt-v3-scenes/barcelona-pavilion/textures/sky.exr"),
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
    look_from = Pnt3(-10, 2.25, 10) 
    look_at = Pnt3(7, 1.75, -3)
    up = Vec3(0, 1, 0)
    screen = Bounds2(Pnt2(-1, -1), Pnt2(1, 1))
    C = PerspectiveCamera(LookAt(look_from, look_at, up), screen, 0.0, 1.0, 0.0, 1e6, 45.0, film)

    # Instantiate a Sampler
    # S = ZSobolSampler(parsed_args["samples-per-pixel"], film.full_resolution, Int8(2))
    S = StratifiedSampler(parsed_args["samples-per-pixel"], parsed_args["jitter"])
    print("Using " * num2str(S.samples_per_pixel) * " samples per pixel\n")
    
    # Instantiate Scene
    print("There are " * num2str(length(lights)) * " lights in the scene\n")
    scene = Scene(lights, bvh)
    
    # Instantiate an Integrator
    I = BDPTIntegrator(C, S, parsed_args["max-depth"])
    return I, scene
end
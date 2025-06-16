function make_scene21(parsed_args::Dict)::Tuple{AbstractIntegrator, Scene}
    primitives = Primitive[]
    lights = Light[]

    path_header = "/Users/johnmyslinski/Documents/pbrt-v3-scenes/sanmiguel/"

    # materials
    mat_vidrio = Glass(
        ConstantTexture(spectrum_from_float(1.0, 1.0, 1.0)),
        ConstantTexture(spectrum_from_float(1.0, 1.0, 1.0)),
        ConstantTexture(0.0),
        ConstantTexture(0.0),
        ConstantTexture(1.5),
        nothing,
        true
    )
    mat_jardinera_1 = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/jardinera_1_color.png"),
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(),
                jmfp(path_header * "textures/jardinera_1_displacement_2.png"), 
                true
            ),
            ConstantTexture(0.001)
        )
    )
    mat_moldura_detalle_escalera = Matte(
        ImageTexture(
            UVMapping2D(),
            jmpf(path_header * "textures/cantera_naranja_liso.png"),
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    mat_moldura_techo_arcos = Matte(
        ImageTexture(
            UVMapping2D(),
            jmpf(path_header * "textures/moldura_volado.png"),
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    mat_moldura_techo = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/moldura_techo.png"),
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(),
                jmfp(path_header * "textures/moldura_techo_bump.png"), 
                true
            ),
            ConstantTexture(0.001)
        )
    )
    mat_escalera = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/escalera_color.png"),
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(),
                jmfp(path_header * "textures/escalera_bump.png"), 
                true
            ),
            ConstantTexture(0.001)
        )
    )
    mat_muros = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/pared_barro_afinado.png"),
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    mat_techos = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/techo.png"),
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    mat_vigas_concreto = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/concreto_02.png"),
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    mat_moldura_volado = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/moldura_volado.png"),
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    mat_losa_volados = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/losa.png"),
            false
        ),
        ConstantTexture(0.0),
        nothing
    )
    mat_moldura_2_piso = Matte(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/moldura2piso_color.png"),
            false
        ),
        ConstantTexture(0.0),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(),
                jmfp(path_header * "textures/moldura2piso_bump.png"), 
                true
            ),
            ConstantTexture(0.003)
        )
    )
    mat_piso_interior = Matte(
        ConstantTexture(spectrum_from_float(0.75, 0.75, 0.75)),
        ConstantTexture(0.0),
        nothing
    )
    mat_azotea = Matte(
        ConstantTexture(spectrum_from_float(0.54902, 0.54902, 0.54902)),
        ConstantTexture(0.0),
        nothing
    )
    piso_pasillos_arriba = Plastic(
        ImageTexture(
            UVMapping2D(),
            jmfp(path_header * "textures/piso_rustico.png"), 
            false
        ),
        MixMultTexture(
            ImageTexture(
                UVMapping2D(),
                jmfp(path_header * "textures/piso_rustico_Spec.png"), 
                false
            ),
            ConstantTexture(spectrum_from_float(1.0, 1.0, 1.0))
        ),
        ConstantTexture(0.005),
        nothing,
        nothing,
        MixMultTexture(
            ImageTexture(
                UVMapping2D(),
                jmfp(path_header * "textures/piso_rustico_displace2.png"), 
                true
            ),
            ConstantTexture(0.012)
        ),
        true
    )

    mat_dict = Dict{String, Material}()

    mat_dict["sanmiguel_00001_ascii.obj"] = mat_vidrio
    mat_dict["sanmiguel_00073_ascii.obj"] = mat_vidrio

    mat_dict["sanmiguel_00002_ascii.obj"] = mat_jardinera_1
    mat_dict["sanmiguel_00003_ascii.obj"] = mat_jardinera_1

    mat_dict["sanmiguel_00004_ascii.obj"] = mat_moldura_detalle_escalera

    mat_dict["sanmiguel_00005_ascii.obj"] = mat_moldura_techo_arcos

    mat_dict["sanmiguel_00006_ascii.obj"] = mat_moldura_techo

    mat_dict["sanmiguel_00007_ascii.obj"] = mat_escalera

    mat_dict["sanmiguel_00008_ascii.obj"] = mat_muros
    mat_dict["sanmiguel_00037_ascii.obj"] = mat_muros
    mat_dict["sanmiguel_00041_ascii.obj"] = mat_muros

    mat_dict["sanmiguel_00009_ascii.obj"] = mat_techos

    mat_dict["sanmiguel_00010_ascii.obj"] = mat_vigas_concreto

    mat_dict["sanmiguel_00011_ascii.obj"] = mat_moldura_volado

    mat_dict["sanmiguel_00012_ascii.obj"] = mat_losa_volados

    mat_dict["sanmiguel_00013_ascii.obj"] = mat_moldura_2_piso

    mat_dict["sanmiguel_00014_ascii.obj"] = mat_piso_interior
    mat_dict["sanmiguel_00016_ascii.obj"] = mat_piso_interior
    mat_dict["sanmiguel_00018_ascii.obj"] = mat_piso_interior

    mat_dict["sanmiguel_00015_ascii.obj"] = mat_azotea

    mat_dict["sanmiguel_00017_ascii.obj"] = piso_pasillos_arriba

    commented_in = keys(mat_dict)

    dirpath = jmfp("/Users/johnmyslinski/Documents/pbrt-v3-scenes/sanmiguel/geometry/")
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
                    tmp_mat = mat_dict[obj_file]
                    push!(primitives, Primitive(mesh, tmp_mat, nothing))
                end
            end
        end
    end

    # instantiate accelerator
    print("\nThere are " * num2str(length(primitives)) * " objects in the scene, building BVH\n")
    @time bvh = BVH(primitives)
    print("Done building BVH\n")

    # instantiate the infinite light
    l_2_w = RotateZ(198.0)
    light = InfiniteLight(
        world_bounds(bvh), 
        l_2_w, 
        spectrum_from_float(13.0, Illuminant), 
        jmfp("/Users/johnmyslinski/Documents/pbrt-v3-scenes/sanmiguel/textures/RenoSuburb01_sm.exr"),
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
    look_from = Pnt3(27.6255, -2.42353, 1.49616)
    look_at = Pnt3(26.6582, -2.17012, 1.48803)
    up = Vec3(-0.00786446, 0.00206023, 0.999967)
    screen = Bounds2(Pnt2(-1, -1), Pnt2(1, 1))
    C = PerspectiveCamera(LookAt(look_from, look_at, up) * Scale(-1.0, 1.0, 1.0), screen, 0.0, 1.0, 0.0, 1e6, 57.2209, film)

    # Instantiate a Sampler
    S = ZSobolSampler(
        parsed_args["samples-per-pixel"], 
        Pnt2i(parsed_args["image-dim"][1], parsed_args["image-dim"][2]), 
        Int8(2),
        parsed_args["seed"]
    )
    # S = StratifiedSampler(parsed_args["samples-per-pixel"], parsed_args["jitter"])
    print("Using " * num2str(S.samples_per_pixel) * " samples per pixel\n")
    
    # Instantiate Scene
    print("There are " * num2str(length(lights)) * " lights in the scene\n")
    scene = Scene(lights, bvh)
    
    # Instantiate an Integrator
    I = BDPTIntegrator(C, S, parsed_args["max-depth"])

    return I, scene
end
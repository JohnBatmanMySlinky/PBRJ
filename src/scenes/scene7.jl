function make_scene7(parsed_args::Dict)::Tuple{AbstractIntegrator, Scene}
    primitives = Primitive[]
    primitives2 = Primitive[]
    lights = Light[]
    materials = Material[]

    # MATERIALS
    mat_gray = Matte(
        "mat_gray",
        ConstantTexture(spectrum_from_float(.4, .4, .4)),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_gray)

    mat_dark_gray = Matte(
        "mat_dark_gray",
        ConstantTexture(spectrum_from_float(.1, .1, .1)),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_dark_gray)

    mat_white = Matte(
        "mat_white",
        ConstantTexture(spectrum_from_float(1.0, 1.0, 1.0)),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_white)

    mat_julia_green = Matte(
        "mat_julia_green",
        ConstantTexture(spectrum_from_float(0.22, 0.596, .149)),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_julia_green)

    mat_julia_purple = Matte(
        "mat_julia_purple",
        ConstantTexture(spectrum_from_float(0.584, .345, .698)),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_julia_purple)

    mat_julia_red = Matte(
        "mat_julia_red",
        ConstantTexture(spectrum_from_float(.796, .235, .2)),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_julia_red)

    name_index = Dict(mat.name => i for (i, mat) in enumerate(materials))
    MATERIAL_REGISTRY[] = MaterialRegistry(materials, name_index)

    #######################
    # instantiate objects #
    #######################
    # walls
    identity_shape_core = ShapeCore()
    floor = Rectangle(
        Pnt2(-250, -250), 
        Pnt2(250, 250), 
        0.0,
        2, 
        identity_shape_core,
        false,
        nothing
    )
    for tri in floor
        push!(primitives, Primitive(tri, "mat_gray", nothing))
    end

    back_wall = Rectangle(
        Pnt2(0, -100), 
        Pnt2(75, 100), 
        -100.0,
        1, 
        identity_shape_core,
        false,
        nothing
    )
    for tri in back_wall
        push!(primitives, Primitive(tri, "mat_gray", nothing))
    end

    side_wall = Rectangle(
        Pnt2(-100, 0), 
        Pnt2(100, 75), 
        -45.0,
        3, 
        identity_shape_core,
        false,
        nothing
    )
    for tri in side_wall
        push!(primitives, Primitive(tri, "mat_gray", nothing))
    end

    for i in 0:6
        start = -100
        width = 20
        space = 10
        rafter = Box(
            Pnt3(start + i * (width + space),         75,  -250),
            Pnt3(start + i * (width + space) + width, 100,  250),
            identity_shape_core,
            nothing
        )
        for tri in rafter
            push!(primitives, Primitive(tri, "mat_white", nothing))
        end

        light_tris = Rectangle(
            Pnt2(start +     i   * (width + space) + width + 1.0, -250), 
            Pnt2(start + (i + 1) * (width + space)         - 1.0, 250), 
            95.0,
            2, 
            identity_shape_core,
            true,
            nothing
        )
        for tri in light_tris
            alight = DiffuseAreaLight(
                spectrum_from_float(4.0),
                tri,
                false
            )
            push!(lights, alight)
            push!(primitives, Primitive(tri, "mat_white", alight))
        end
        # print(
        #     "       Box $(i+1)
        #             - start: $(start + i * (width + space))
        #             - end: $(start + i * (width + space) + width)
        #             Light $(i+1)
        #             - start: $(start +     i * (width + space) + width + 1.0)
        #             - end: $(start + (i + 1) * (width + space)         - 1.0)\n\n\n
        #     "
        # )
    end

    # asdf = 20.0
    # sphere1_t = Translate(Pnt3(0, 20, asdf/2.0))
    # sphere1_sc = ShapeCore(sphere1_t, Inv(sphere1_t), false, false)
    # sphere1 = Sphere(sphere1_sc, asdf/2.0)
    # push!(primitives, Primitive(sphere1, mat_julia_red, nothing))

    # sphere2_t = Translate(Pnt3(0, 20, -asdf/2.0))
    # sphere2_sc = ShapeCore(sphere2_t, Inv(sphere2_t), false, false)
    # sphere2 = Sphere(sphere2_sc, asdf/2.0)
    # push!(primitives, Primitive(sphere2, mat_julia_purple, nothing))

    # sphere3_t = Translate(Pnt3(0, 20 + sqrt(asdf^2 - (asdf/2.0)^2), 0))
    # sphere3_sc = ShapeCore(sphere3_t, Inv(sphere3_t), false, false)
    # sphere3 = Sphere(sphere3_sc, asdf/2.0)
    # push!(primitives, Primitive(sphere3, mat_julia_green, nothing))

    asdf = 20.0
    teapot_scale = 0.175
    teapot_y_shift = 20
    rotate_y = 45.0
    z_scale = 1.2
    y_scale = 0.95
    teapot_t1 = Translate(Pnt3(0, teapot_y_shift, asdf/2.0 * z_scale)) * RotateY(rotate_y) * Scale(Vec3(teapot_scale, teapot_scale, teapot_scale))
    teapot1 = parse_obj("../ref/teapot.obj", teapot_t1, false, false, nothing) 
    for tris in teapot1
        for tri in tris
            push!(primitives, Primitive(tri, "mat_julia_red", nothing))
        end
    end

    teapot_t2 = Translate(Pnt3(0, teapot_y_shift, -asdf/2.0 * z_scale)) * RotateY(rotate_y) * Scale(Vec3(teapot_scale, teapot_scale, teapot_scale))
    teapot2 = parse_obj("../ref/teapot.obj", teapot_t2, false, false, nothing) 
    for tris in teapot2
        for tri in tris
            push!(primitives, Primitive(tri, "mat_julia_purple", nothing))
        end
    end

    teapot_t3 = Translate(Pnt3(0, teapot_y_shift + sqrt(asdf^2 - (asdf/2.0)^2) * y_scale, 0)) * RotateY(rotate_y) * Scale(Vec3(teapot_scale, teapot_scale, teapot_scale))
    teapot3 = parse_obj("../ref/teapot.obj", teapot_t3, false, false, nothing) 
    for tris in teapot3
        for tri in tris
            push!(primitives, Primitive(tri, "mat_julia_green", nothing))
        end
    end

    Random.seed!(parsed_args["seed"])
    N_DODECA = 50
    area_1_box = Bounds3(
        Pnt3(-80, 10, -180),
        Pnt3(-10, 60, 60)
    )
    area_2_box = Bounds3(
        Pnt3(10, 10, -180),
        Pnt3(80, 60, 60)
    )
    for box in [area_1_box, area_2_box]
        for _ in 1:N_DODECA
            scale = (rand() + 1.0)
            translate = Pnt3(
                (box.pMax.x - box.pMin.x) * rand() + box.pMin.x,
                (box.pMax.y - box.pMin.y) * rand() + box.pMin.y,
                (box.pMax.z - box.pMin.z) * rand() + box.pMin.z
            )
            platonic_solid_t = Translate(translate) * RotateX(rand() * 360.0) * RotateY(rand() * 360.0) * RotateZ(rand() * 360.0) * Scale(Vec3(scale, scale, scale))
            platonic_solid = parse_obj("/Users/johnmyslinski/Documents/PBRJ/ref/dodecahedron.obj", platonic_solid_t, false, false, nothing)
            for tris in platonic_solid
                for tri in tris
                    push!(primitives, Primitive(tri, "mat_dark_gray", nothing))
                end
            end
        end
    end

    # instantiate lights
    light_t = Translate(Pnt3(0, 100, 0))
    light_sc = ShapeCore(light_t, Inv(light_t), false, false)
    light_tris = Rectangle(
        Pnt2(-50, -50), 
        Pnt2(50, 50), 
        0.0,
        2, 
        light_sc,
        true,
        nothing
    )
    for tri in light_tris
        alight = DiffuseAreaLight(
            spectrum_from_float(4.0),
            tri,
            false
        )
        push!(lights, alight)
        push!(primitives, Primitive(tri, "mat_white", alight))
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

    # Instantiate a Camera
    look_from = Pnt3(85, 35, 35)
    look_at = Pnt3(0, teapot_y_shift + sqrt(asdf^2 - (asdf/2.0)^2) / 2.0, 0)
    up = Vec3(0, 1, 0)
    C = PerspectiveCamera(LookAt(look_from, look_at, up), 0.0, 1.0, 0.0, 1e6, 55.0, film)

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
function make_scene8(parsed_args::Dict)::Tuple{AbstractIntegrator, Scene}
    primitives = Primitive[]
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
        ConstantTexture(spectrum_from_float(.235, .2, .796)),
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
    end

    # constants
    asdf = 20.0
    teapot_y_shift = 20

    # # test cylindar
    # cylindar_t = LookAt(Pnt3(0, 0, 0), Pnt3(0, 12, 30), Vec3(0, 1, 0)) * RotateX(-90.0)
    # cyl = Cylindar(cylindar_t, 5.0, 0.0, 20.0)
    # push!(primitives, Primitive(cyl, mat_julia_green, nothing))

    d1 = Dict("X" => "F+[[X]-X]-F[-FX]+X", "F" => "FF")
    lsystem_shapes = LSystem(d1, "X", 3)
    for (i, cyl) in enumerate(lsystem_shapes)
        if i % 2 == 0                
            push!(primitives, Primitive(cyl, "mat_julia_red", nothing))
        else
            push!(primitives, Primitive(cyl, "mat_julia_green", nothing))
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

    # Instantiate a Camera
    look_from = Pnt3(85, 35, 35)
    look_at = Pnt3(0, teapot_y_shift + sqrt(asdf^2 - (asdf/2.0)^2) / 2.0, 0)
    up = Vec3(0, 1, 0)
    C = PerspectiveCamera(LookAt(look_from, look_at, up), nothing, 0.0, 1.0, 0.0, 1e6, 55.0, film)

    # Instantiate a Sampler
    S = StratifiedSampler(parsed_args["samples-per-pixel"], parsed_args["jitter"])
    print("Using " * num2str(S.samples_per_pixel) * " samples per pixel\n")
    
    # Instantiate Scene
    print("There are " * num2str(length(lights)) * " lights in the scene\n")
    scene = Scene(lights, bvh)
    
    # Instantiate an Integrator (default: BDPT)
    integrator_arg = parsed_args["integrator"]
    if integrator_arg == "default"
        I = BDPTIntegrator(C, S, parsed_args["max-depth"])
    elseif integrator_arg == "bdpt"
        I = BDPTIntegrator(C, S, parsed_args["max-depth"])
    elseif integrator_arg == "volpath"
        I = VolPathIntegratorv3(C, S, parsed_args["max-depth"])
    elseif integrator_arg == "sppm"
        I = SPPMIntegrator(C, S, C.film, parsed_args["max-depth"], parsed_args["n-iterations"], parsed_args["photons-per-iteration"], 1.0)
    else
        error("Unknown integrator: $(integrator_arg)")
    end
    return I, scene
end
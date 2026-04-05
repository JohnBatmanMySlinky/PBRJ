function make_scene9(parsed_args::Dict)::Tuple{AbstractIntegrator, Scene}
    primitives = Primitive[]
    lights = Light[]
    materials = Material[]

    # materials
    mat_inner = Metal(
        "mat_inner"
    )
    push!(materials, mat_inner)

    mat_outer = Fourier(
        "mat_outer",
        jmfp("/Users/johnmyslinski/Documents/pbrt-v3-scenes/lte-orb/bsdfs/roughglass_alpha_0.2.bsdf"),
        nothing
    )
    push!(materials, mat_outer)

    mat_ground = Matte(
        "mat_ground",
        ConstantTexture(spectrum_from_float(0.2, 0.2, 0.2)),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_ground)

    brightness = spectrum_from_float(9.5, 9.5, 9.5)
    mat_light = Matte(
        "mat_light",
        ConstantTexture(brightness),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_light)

    name_index = Dict(mat.name => i for (i, mat) in enumerate(materials))
    MATERIAL_REGISTRY[] = MaterialRegistry(materials, name_index)

    ##############
    ### a mesh ###
    ##############

    mesh012_translate = Translate(Pnt3(0,0,0)) 
    mesh0 =  parse_obj(
        jmfp("/Users/johnmyslinski/Documents/pbrt-v4-scenes/lte-orb/geometry/mesh-0_ascii.obj"), # inner
        mesh012_translate,
        true,
        false,
        nothing
    )
    for tris in mesh0
        for tri in tris
            push!(primitives, Primitive(tri, "mat_inner", nothing))
        end
    end
    mesh1 =  parse_obj(
        jmfp("/Users/johnmyslinski/Documents/pbrt-v4-scenes/lte-orb/geometry/mesh-1_ascii.obj"), # base
        mesh012_translate,
        true,
        false,
        nothing
    )
    for tris in mesh1
        for tri in tris
            push!(primitives, Primitive(tri, "mat_outer", nothing))
        end
    end
    mesh2 =  parse_obj(
        jmfp("/Users/johnmyslinski/Documents/pbrt-v4-scenes/lte-orb/geometry/mesh-2_ascii.obj"), # outer
        mesh012_translate,
        true,
        false,
        nothing
    )
    for tris in mesh2
        for tri in tris
            push!(primitives, Primitive(tri, "mat_outer", nothing))
        end
    end

    ground_tris = Rectangle(
        Pnt2(-5, -5),
        Pnt2(5, 5),
        0.0,
        2,
        ShapeCore(),
        false,
        nothing
    )
    for tri in ground_tris
        push!(primitives, Primitive(tri, "mat_ground", nothing))
    end

    tris = construct_triangle_mesh(
        ShapeCore(),
        2,
        Pnt3[
            Pnt3(-1, 3.204596996, -0.9997209907), 
            Pnt3(1, 3.204596996, -0.9997209907),
            Pnt3(1, 3.251826048, 0.9997209907), 
            Pnt3(-1, 3.251826048, 0.9997209907)
        ],
        Int64[1, 2, 3, 1, 3, 4],
        nothing, nothing,
        nothing, nothing,
        nothing
    )
    for tri in tris
        alight = DiffuseAreaLight(
            brightness,
            tri,
            false
        )
        push!(lights, alight)
        push!(primitives, Primitive(tri, "mat_ground", alight))
    end

    # instantiate accelerator
    print("\nThere are " * num2str(length(primitives)) * " objects in the scene, building BVH\n")
    @time bvh = BVH(primitives)
    print("Done building BVH\n")

    # instantiate the infinite light
    l_2_w = Rotate(-90.0, Vec3(1,0,0))
    light = InfiniteLight(
        world_bounds(bvh), 
        l_2_w, 
        Spectrum(1.4, 1.4, 1.4), 
        jmfp("/Users/johnmyslinski/Documents/pbrt-v4-scenes/lte-orb/textures/small_rural_road_equiarea.exr"),
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
    look_from = Pnt3(0.2, 0.4, -0.5)
    look_at = Pnt3(0, 0.1, 0)
    up = Vec3(0, 1, 0)
    C = PerspectiveCamera(LookAt(look_from, look_at, up) * Scale(-1.0, 1.0, 1.0), nothing, 0.0, 1.0, 0.0, 1e6, 37.0, film)

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
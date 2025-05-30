function make_scene9(parsed_args::Dict)::Tuple{AbstractIntegrator, Scene}
    primitives = Primitive[]
    lights = Light[]

    # materials
    mat_inner = Matte(
        ConstantTexture(spectrum_from_float(1.0, 0.0, 0.0)),
        ConstantTexture(0.0),
        nothing
    )
    mat_outer = Matte(
        ConstantTexture(spectrum_from_float(0.0, 1.0, 0.0)),
        ConstantTexture(0.0),
        nothing
    )
    mat_stand = Matte(
        ConstantTexture(spectrum_from_float(0.0, 0.0, 1.0)),
        ConstantTexture(0.0),
        nothing
    )

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
            push!(primitives, Primitive(tri, mat_inner, nothing))
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
            push!(primitives, Primitive(tri, mat_stand, nothing))
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
            push!(primitives, Primitive(tri, mat_outer, nothing))
        end
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
    screen = Bounds2(Pnt2(-1, -1), Pnt2(1, 1))
    C = PerspectiveCamera(LookAt(look_from, look_at, up) * Scale(-1.0, 1.0, 1.0), screen, 0.0, 1.0, 0.0, 1e6, 37.0, film)

    # Instantiate a Sampler
    S = StratifiedSampler(parsed_args["samples-per-pixel"], parsed_args["jitter"])
    print("Using " * num2str(S.samples_per_pixel) * " samples per pixel\n")
    
    # Instantiate Scene
    print("There are " * num2str(length(lights)) * " lights in the scene\n")
    scene = Scene(lights, bvh)
    
    # Instantiate an Integrator
    I = BDPTIntegrator(C, S, parsed_args["max-depth"])
    return I, scene
end
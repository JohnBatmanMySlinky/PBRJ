function make_scene9(parsed_args::Dict)::Tuple{AbstractIntegrator, Scene}
    primitives = Primitive[]
    lights = Light[]

    # materials
    mat_inner = Matte(
        ConstantTexture(spectrum_from_float(1.0, 0.0, 0.0)),
        ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
        nothing
    )
    mat_outer = Matte(
        ConstantTexture(spectrum_from_float(0.0, 1.0, 0.0)),
        ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
        nothing
    )
    mat_stand = Matte(
        ConstantTexture(spectrum_from_float(0.0, 0.0, 1.0)),
        ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
        nothing
    )

    ##############
    ### a mesh ###
    ##############

    mesh012_translate = Translate(Pnt3(0,0,0)) 
    mesh0 =  parse_obj(
        "../ref/lte-orb/mesh-0.obj", # inner
        mesh012_translate,
        true,
        false,
        nothing
    )
    for tri in mesh0
        push!(primitives, Primitive(tri, mat_inner, nothing))
    end
    mesh1 =  parse_obj(
        "../ref/lte-orb/mesh-1.obj", # base
        mesh012_translate,
        true,
        false,
        nothing
    )
    for tri in mesh1
        push!(primitives, Primitive(tri, mat_stand, nothing))
    end
    mesh2 =  parse_obj(
        "../ref/lte-orb/mesh-2.obj", # outer
        mesh012_translate,
        true,
        false,
        nothing
    )
    for tri in mesh2
        push!(primitives, Primitive(tri, mat_outer, nothing))
    end

    # instantiate accelerator
    print("\nThere are " * num2str(length(primitives)) * " objects in the scene, building BVH\n")
    @time bvh = BVH(primitives)
    print("Done building BVH\n")

    # instantiate the infinite light
    l_2_w = Rotate(-90.0, Vec3(1,0,0))
    light = InfiniteLight(world_bounds(bvh), l_2_w, Spectrum(1.4, 1.4, 1.4), "/Users/johnmyslinski/Documents/pbrt-v4-scenes/lte-orb/textures/small_rural_road_equiarea.exr")
    push!(lights, light)

    # Instantiate a Filter
    filter = BoxFilter(Pnt2(.5, .5))

    # Instantiate a Film
    film = Film(
        Pnt2(parsed_args["image-dim"], parsed_args["image-dim"]),
        Bounds2(Pnt2(parsed_args["crop-window"][1], parsed_args["crop-window"][2]), Pnt2(parsed_args["crop-window"][3], parsed_args["crop-window"][4])),
        filter,
        1.0,
        1.0,
        parsed_args["file-name"]
    )

    # Instantiate a Camera


    # 0.16432909667491913, -0.8644996881484985, -0.6155436635017395
    # 0.27579671144485474, -0.9914534687995911, -0.6511322855949402
    # 0.2510230839252472, -0.9913325309753418, -0.6673218607902527

    look_from = Pnt3(0.0, -0.55, -0.25)
    look_at = Pnt3(0, 0.7, 0)
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
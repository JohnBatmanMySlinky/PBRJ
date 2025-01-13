function make_scene5(parsed_args::Dict)::Tuple{AbstractIntegrator, Scene}
    primitives = Primitive[]
    lights = Light[]

    # MATERIALS
    mat_gray = Matte(
        ConstantTexture(spectrum_from_float(.4, .4, .4)),
        ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
        nothing
    )
    mat_blue = Matte(
        ConstantTexture(spectrum_from_float(0.05, 0.05, .9)),
        ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
        nothing
    )
    mat_white = Matte(
        ConstantTexture(spectrum_from_float(1.0, 1.0, 1.0)),
        ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
        nothing
    )
    mat_metal = Metal()

    # instantiate objects
    identity_shape_core = ShapeCore(
        Translate(Pnt3(0)),
        Translate(Pnt3(0)),
        false,
        false
    )
    floor = Rectangle(
        Pnt2(-25, -25), 
        Pnt2(25, 25), 
        0.0,
        2, 
        identity_shape_core,
        false,
        nothing
    )
    for tri in floor
        push!(primitives, Primitive(tri, mat_gray, nothing))
    end
    light_location_scale = 1.8
    light_intensity_scale = 1.3
    spot_light1 = SpotLight(
        LookAt(light_location_scale * Pnt3(8, 8, 8), Pnt3(0, 0, 0), Vec3(0,-1,0)), 
        light_intensity_scale * spectrum_from_float(245.8113403320, 258.6366500854, 200.3887557983 ), 
        30.0, 
        5.0
    )
    push!(lights, spot_light1)

    spot_light2 = SpotLight(
        LookAt(light_location_scale * Pnt3(-10, 5, -10), Pnt3(0, 0, 0), Vec3(0,-1,0)), 
        light_intensity_scale * spectrum_from_float(200.8113403320, 200.0, 250.3887557983 ), 
        30.0, 
        5.0
    )
    push!(lights, spot_light2)

    spot_light3 = SpotLight(
        LookAt(light_location_scale * Pnt3(-15, 7, 8), Pnt3(0, 0, 0), Vec3(0,-1,0)), 
        light_intensity_scale * spectrum_from_float(350.8113403320, 167.6366500854, 297.3887557983 ), 
        30.0, 
        5.0
    )
    push!(lights, spot_light3)

    spot_light4 = SpotLight(
        LookAt(light_location_scale * Pnt3(5, 20, -5), Pnt3(0, 0, 0), Vec3(0,-1,0)), 
        light_intensity_scale * spectrum_from_float(260.8113403320, 250.6366500854, 290.3887557983 ), 
        30.0, 
        5.0
    )
    push!(lights, spot_light4)

    softy_t = Translate(Pnt3(0, 0, 0))
    softy_core = ShapeCore(
        softy_t,
        Inv(softy_t),
        false,
        false
    )
    # can use a BVH of BasicSpheres
    # meta_balls = MetaBallsBVH(
    #     softy_core, 
    #     BVH([
    #         BasicSphere(Pnt3(asdf/2,  3.0, 0.0), 3.0),
    #         BasicSphere(Pnt3(-asdf/2, 3.0, 0.0), 3.0),
    #         BasicSphere(Pnt3(0.0,     3.0, sqrt(asdf^2 - (asdf/2)^2)), 3.0)
    #     ])
    # )

    N = 4
    R = 13
    points = Pnt3[]
    for x in 1:N
        for z in 1:N
            px = (x - 0.5) / N * R - R / 2.0
            pz = (z - 0.5) / N * R - R / 2.0
            if (x == N-N/2) || (z == N-N/2)
                adj = 4.0
            else
                adj =  (1.0 / ((N-x-N/2)^2)) + (1.0 / ((N-z-N/2)^2))
            end
            p = Pnt3(px, 3.0 + adj, pz)
            print("Meta Ball: $(p)\n")
            push!(points, p)
        end
    end
    meta_balls = MetaBalls(
        softy_core, 
        points
    )
    push!(primitives, Primitive(meta_balls, mat_blue, nothing))

    # instantiate accelerator
    print("\nThere are " * num2str(length(primitives)) * " objects in the scene, building BVH\n")
    @time bvh = BVH(primitives)
    print("Done building BVH\n")

    # l_2_w = Translate(Pnt3(0,0,0))
    # light = InfiniteLight(
    #     world_bounds(bvh), 
    #     l_2_w, 
    #     Spectrum(2.0, 2.0, 2.0), 
    #     "/Users/johnmyslinski/Documents/pbrt-v3-scenes/cloud/textures/skylight-morn.exr"
    # )
    # push!(lights, light)

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
    look_from = Pnt3(20, 30, 10)
    look_at = Pnt3(0, 0, 0)
    up = Vec3(0, 1, 0)
    screen = Bounds2(Pnt2(-1, -1), Pnt2(1, 1))
    C = PerspectiveCamera(LookAt(look_from, look_at, up), screen, 0.0, 1.0, 0.0, 1e6, 55.0, film)

    # Instantiate a Sampler
    S = ZSobolSampler(parsed_args["samples-per-pixel"], Pnt2(parsed_args["image-dim"], parsed_args["image-dim"]), Int8(2))
    print("Using " * num2str(S.samples_per_pixel) * " samples per pixel\n")
    
    # Instantiate Scene
    print("There are " * num2str(length(lights)) * " lights in the scene\n")
    scene = Scene(lights, bvh)
    
    # Instantiate an Integrator
    I = BDPTIntegrator(C, S, parsed_args["max-depth"])
    return I, scene
end
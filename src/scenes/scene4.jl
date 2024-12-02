function make_scene4(parsed_args::Dict)::Tuple{AbstractIntegrator, Scene}
    primitives = Primitive[]
    lights = Light[]

    # MATERIALS
    mat_gray = Matte(
        ConstantTexture(spectrum_from_float(0.725, 0.71, 0.68)),
        ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
        nothing
    )
    mat_white = Matte(
        ConstantTexture(spectrum_from_float(1.0, 1.0, 1.0)),
        ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
        nothing
    )
    mat_red = Matte(
        ConstantTexture(spectrum_from_float(0.63, 0.065, 0.05)),
        ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
        nothing
    )
    mat_green = Matte(
        ConstantTexture(spectrum_from_float(0.14, 0.45, 0.091)),
        ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
        nothing
    )
    mat_blue = Matte(
        ConstantTexture(spectrum_from_float(0.14, 0.09, 0.68)),
        ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
        nothing
    )

    # instantiate objects
    identity_shape_core = ShapeCore(
        Translate(Pnt3(0)),
        Translate(Pnt3(0)),
        false,
        false
    )
    floor = Rectangle(
        Pnt2(0, 0), 
        Pnt2(555, 555), 
        0.0,
        2, 
        identity_shape_core,
        false,
        nothing
    )
    for tri in floor
        push!(primitives, Primitive(tri, mat_gray, nothing))
    end
    ceiling = Rectangle(
        Pnt2(0, 0), 
        Pnt2(555, 555), 
        555.0,
        2, 
        ShapeCore(Translate(Pnt3(0)),Translate(Pnt3(0)),true,false),
        false,
        nothing
    )
    for tri in ceiling
        push!(primitives, Primitive(tri, mat_gray, nothing))
    end
    backwall = Rectangle(
        Pnt2(0, 0), 
        Pnt2(555, 555), 
        555.0,
        3, 
        identity_shape_core,
        true,
        nothing
    )
    for tri in backwall
        push!(primitives, Primitive(tri, mat_blue, nothing))
    end
    leftwall = Rectangle(
        Pnt2(0, 0), 
        Pnt2(555, 555), 
        0.0,
        1, 
        identity_shape_core,
        true,
        nothing
    )
    for tri in leftwall
        push!(primitives, Primitive(tri, mat_red, nothing))
    end
    rightwall = Rectangle(
        Pnt2(0, 0), 
        Pnt2(555, 555), 
        555.0,
        1, 
        identity_shape_core,
        false,
        nothing
    )
    for tri in rightwall
        push!(primitives, Primitive(tri, mat_green, nothing))
    end

    ceiling_light = Rectangle(
        Pnt2(213, 213), 
        Pnt2(343, 343), 
        554.0,
        2, 
        identity_shape_core,
        true,
        nothing
    )
    for tri in reverse(ceiling_light)
        alight = DiffuseAreaLight(
            spectrum_from_float(17.0, 12.0, 4.0, Illuminant),
            tri,
            false # NOT two sided
        )
        push!(lights,alight)
        push!(primitives, Primitive(tri, mat_white, alight))
    end
    #######################################
    ###### FOR VALIDATION USE SPHERE ######
    #######################################
    # My triangle sample is using pbrtv4 not v3 so use a spehere to make validating against v3 easier
    # s = Sphere(
    #     ShapeCore(
    #         Translate(Pnt3(0, 525, 0)),
    #         Inv(Translate(Pnt3(0, 525, 0))),
    #         false,
    #         false
    #     ),
    #     25.0
    # )
    # alight = DiffuseAreaLight(
    #     spectrum_from_float(200.0, 200.0, 200.0, Illuminant),
    #     s,
    #     false
    # )
    # push!(lights, alight)
    # push!(primitives, Primitive(s, mat_white, alight))

    # box_1_transform = Translate(Pnt3(265, 0, 295)) * RotateY(25.0)
    # box_1 = Box(
    #     Pnt3(0,0,0), 
    #     Pnt3(165,  330, 165), 
    #     ShapeCore(box_1_transform, Inv(box_1_transform), false, false),
    #     nothing
    # )
    # for tri in box_1
    #     push!(primitives, Primitive(tri, mat_gray, nothing))
    # end

    # box_2_transform = Translate(Pnt3(130, 0, 65)) * RotateY(-18.0)
    # box_2 = Box(
    #     Pnt3(0,0,0), 
    #     Pnt3(165,  165, 165), 
    #     ShapeCore(box_2_transform, Inv(box_2_transform), false, false),
    #     nothing
    # )
    # for tri in box_2
    #     push!(primitives, Primitive(tri, mat_gray, nothing))
    # end

    sphere_transform = Translate(Pnt3(278, 278, 278))
    sphere = Sphere(
        ShapeCore(
            sphere_transform,
            Inv(sphere_transform),
            false,
            false
        ),
        45.0
    )
    smoke_mi = MediumInterface(
        HomogenousMedium(spectrum_from_float(0.001), spectrum_from_float(0.015)),
        nothing
    )
    push!(primitives, Primitive(sphere, nothing, nothing, smoke_mi))

    # instantiate accelerator
    print("\nThere are " * num2str(length(primitives)) * " objects in the scene, building BVH\n")
    @time bvh = BVH(primitives)
    print("Done building BVH\n")
    print("Scene Bounds $(world_bounds(bvh))")

    # Instantiate a Filter
    filter = BoxFilter(Pnt2(.1, .1))

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
    look_from = Pnt3(278, 278, -800)
    look_at = Pnt3(278, 278, 0)
    up = Vec3(0, 1, 0)
    screen = Bounds2(Pnt2(-1, -1), Pnt2(1, 1))
    C = PerspectiveCamera(LookAt(look_from, look_at, up), screen, 0.0, 1.0, 0.0, 1e6, 40.0, film)

    # Instantiate a Sampler
    S = ZSobolSampler(parsed_args["samples-per-pixel"], film.full_resolution, Int8(2))
    print("Using " * num2str(S.samples_per_pixel) * " samples per pixel\n")
    
    # Instantiate Scene
    print("There are " * num2str(length(lights)) * " lights in the scene\n")
    scene = Scene(lights, bvh)
    
    # Instantiate an Integrator
    I = BDPTIntegrator(C, S, parsed_args["max-depth"])

    return I, scene
end
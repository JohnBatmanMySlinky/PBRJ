function make_scene23(parsed_args::Dict)::Tuple{AbstractIntegrator, Scene}
    primitives = Primitive[]
    lights = Light[]
    materials = Material[]

    mat_glass = Glass(
        "mat_glass",
        ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
        ConstantTexture(spectrum_from_float(0.75, 0.75, 0.75)),
        ConstantTexture(0.0),
        ConstantTexture(0.0),
        ConstantTexture(1.328),
        nothing,
        true
    )
    push!(materials, mat_glass)

    mat_red = Matte(
        "mat_red",
        ConstantTexture(spectrum_from_float(0.5, 0.5, 0.5)),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_red)

    mat_blue = Matte(
        "mat_blue",
        ConstantTexture(spectrum_from_float(0.5, 0.5, 0.5)),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_blue)

    mat_white = Matte(
        "mat_white",
        ConstantTexture(spectrum_from_float(0.7, 0.7, 0.7)),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_white)

    mat_ball0 = Metal(
        "mat_ball0"
    )
    push!(materials, mat_ball0)

    mat_ball1 = Glass(
        "mat_ball1",
        ConstantTexture(spectrum_from_float(0.0, 0.0, 0.0)),
        ConstantTexture(spectrum_from_float(0.75, 0.75, 0.75)),
        ConstantTexture(0.0),
        ConstantTexture(0.0),
        ConstantTexture(1.5),
        nothing,
        true
    )
    push!(materials, mat_ball1)

    name_index = Dict(mat.name => i for (i, mat) in enumerate(materials))
    MATERIAL_REGISTRY[] = MaterialRegistry(materials, name_index)

    # plane.pbrt: unit plane in XZ, normal pointing +Y, 0-based indices -> 1-based
    plane_verts          = Pnt3[Pnt3(-2.5, 0.0, 2.5), Pnt3(2.5, 0.0, 2.5), Pnt3(2.5, 0.0, -2.5), Pnt3(-2.5, 0.0, -2.5)]
    plane_indices        = Int64[1, 2, 3, 1, 3, 4]
    plane_normals        = Nml3[Nml3(0,1,0), Nml3(0,1,0), Nml3(0,1,0), Nml3(0,1,0)]
    plane_normal_indices = Int64[1, 2, 3, 1, 3, 4]

    for (tr, mat) in [
        # Ground
        (Scale(150.0, 150.0, 150.0),                                                                                                "mat_white"),
        # Side1 (red)
        (Translate(Pnt3(-60.0, 60.0, 0.0)) * Rotate(90.0, Vec3(0,0,1)) * Rotate(180.0, Vec3(1,0,0)) * Scale(150.0, 150.0, 150.0), "mat_red"),
        # Side2 (blue)
        (Translate(Pnt3(60.0, 60.0, 0.0)) * Rotate(90.0, Vec3(0,0,1)) * Scale(150.0, 150.0, 150.0),                               "mat_blue"),
        # Side3 (back wall)
        (Translate(Pnt3(0.0, 60.0, -60.0)) * Rotate(90.0, Vec3(1,0,0)) * Scale(150.0, 150.0, 150.0),                              "mat_white"),
        # Roof
        (Translate(Pnt3(0.0, 120.0, 0.0)) * Rotate(180.0, Vec3(1,0,0)) * Scale(150.0, 150.0, 150.0),                              "mat_white"),
    ]
        for tri in construct_triangle_mesh(
            ShapeCore(tr, Inv(tr), false, false), 2,
            plane_verts, plane_indices,
            plane_normals, plane_normal_indices,
            nothing, nothing, nothing
        )
            push!(primitives, Primitive(tri, mat, nothing))
        end
    end

    # Glass sphere near particle emitter (Translate 49 60 0 / Scale 10 10 10)
    glass_sphere_tr = Translate(Pnt3(49.0, 60.0, 0.0)) * Scale(10.0, 10.0, 10.0)
    glass_sphere = Sphere(ShapeCore(glass_sphere_tr, Inv(glass_sphere_tr), false, false), 1.0)
    push!(primitives, Primitive(glass_sphere, "mat_glass", nothing))

    # Ball0 (metal, Translate 23.5 16.5 31.0 / Scale 16.5 16.5 16.5)
    ball0_tr = Translate(Pnt3(23.5, 16.5, 31.0)) * Scale(16.5, 16.5, 16.5)
    ball0 = Sphere(ShapeCore(ball0_tr, Inv(ball0_tr), false, false), 1.0)
    push!(primitives, Primitive(ball0, "mat_ball0", nothing))

    # Ball1 (glass, Translate -22.5 16.5 0.0 / Scale 16.5 16.5 16.5)
    ball1_tr = Translate(Pnt3(-22.5, 16.5, 0.0)) * Scale(16.5, 16.5, 16.5)
    ball1 = Sphere(ShapeCore(ball1_tr, Inv(ball1_tr), false, false), 1.0)
    push!(primitives, Primitive(ball1, "mat_ball1", nothing))

    print("\nThere are " * num2str(length(primitives)) * " objects in the scene, building BVH\n")
    @time bvh = BVH(primitives)
    print("Done building BVH\n")

    # Particle emitter: disk at Translate(59.5,60,0) * Rotate(-90,Y) * Rotate(90,Z), radius 10
    # The disk faces inward (toward the glass sphere at x=49)
    pe_tr = Translate(Pnt3(59.5, 60.0, 0.0)) * RotateY(-90.0) * RotateZ(90.0)
    pe_disk = Disk(pe_tr, 0.0, 10.0, 0.0, 360.0, false, false)
    particle_emitter = ParticleEmitter(
        pe_disk;
        velocity        = 0.8,
        range           = 50.0,
        cherenkov_scale = 1_000.0,
        uniform_scale   = 50.0,
        ambient_eta     = ETA_AIR,
        n_particles     = 1,
        seed            = 0
    )
    preprocess!(particle_emitter, bvh)
    push!(lights, particle_emitter)

    # Commented out in the pbrt file but kept here as an option:
    # point_light = PointLight(
    #     Translate(Pnt3(0.0, 118.5, 0.0)),
    #     spectrum_from_float(4000.0, Illuminant)
    # )
    # push!(lights, point_light)

    filter = BoxFilter(Pnt2(0.5, 0.5))
    film = Film(
        Pnt2i(parsed_args["image-dim"][1], parsed_args["image-dim"][2]),
        Bounds2(Pnt2(parsed_args["crop-window"][1], parsed_args["crop-window"][2]), Pnt2(parsed_args["crop-window"][3], parsed_args["crop-window"][4])),
        filter,
        1.0,
        1.0,
        parsed_args["file-name"]
    )

    look_from = Pnt3(0, 60, 180)
    look_at   = Pnt3(0, 60, 0)
    up        = Vec3(0, 1, 0)
    C = PerspectiveCamera(LookAt(look_from, look_at, up) * Scale(-1.0, 1.0, 1.0), nothing, 0.0, 1.0, 0.0, 1e6, 52.0, film)

    S = ZSobolSampler(
        parsed_args["samples-per-pixel"],
        Pnt2i(parsed_args["image-dim"][1], parsed_args["image-dim"][2]),
        Int8(2),
        parsed_args["seed"]
    )
    print("Using " * num2str(S.samples_per_pixel) * " samples per pixel\n")

    print("There are " * num2str(length(lights)) * " lights in the scene\n")
    scene = Scene(lights, bvh)

    # Instantiate an Integrator (default: SPPM)
    integrator_arg = parsed_args["integrator"]
    if integrator_arg == "default"
        I = SPPMIntegrator(C, S, film, parsed_args["max-depth"], parsed_args["n-iterations"], parsed_args["photons-per-iteration"], 1.0)
    elseif integrator_arg == "bdpt"
        I = BDPTIntegrator(C, S, parsed_args["max-depth"])
    elseif integrator_arg == "volpath"
        I = VolPathIntegratorv3(C, S, parsed_args["max-depth"])
    elseif integrator_arg == "sppm"
        I = SPPMIntegrator(C, S, film, parsed_args["max-depth"], parsed_args["n-iterations"], parsed_args["photons-per-iteration"], 1.0)
    else
        error("Unknown integrator: $(integrator_arg)")
    end

    return I, scene
end

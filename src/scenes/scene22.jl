function make_scene22(parsed_args::Dict)::Tuple{AbstractIntegrator, Scene}
    primitives = Primitive[]
    lights = Light[]
    materials = Material[]

    mat_gray = Matte(
        "mat_gray",
        ConstantTexture(spectrum_from_float(0.75, 0.75, 0.75)),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_gray)

    name_index = Dict(mat.name => i for (i, mat) in enumerate(materials))
    MATERIAL_REGISTRY[] = MaterialRegistry(materials, name_index)

    explosion_mi = MediumInterface(
        NanoVDBMedium(
            Translate(Pnt3(0, 0, 0)),                   # medium is already in world space
            spectrum_from_float(0.4, 0.4, 0.4), # sigma_a
            spectrum_from_float(0.9, 0.9, 0.9), # sigma_s
            0.0,                                # g
            5.0,                                # scale
            jmfp("/Users/johnmyslinski/Documents/pbrt-v4-volumes/scenes/ground_explosion/geometry/ground_explosion-RENDER-0.190.nvdb"),
            Pnt3i(16, 16, 16),
            1.25,                               # Le_scale
            0.0,                                # temperature_offset
            4500.0,                             # temperature_scale
        ),
        nothing
    )
    indices = Int64[0, 3, 1, 0, 2, 3, 4, 7, 5, 4, 6, 7, 6, 2, 7, 6, 3, 2, 5, 1, 4, 5, 0, 1, 5, 2, 0, 5, 7, 2, 1, 6, 4, 1, 3, 6] .+ 1
    for tri in construct_triangle_mesh(ShapeCore(), 12, Pnt3[
            Pnt3(33.000008, -0.074999996, 31.900047), Pnt3(-30.29999, -0.074999996, 31.900047),
            Pnt3(33.000008, 89.475, 31.900047), Pnt3(-30.29999, 89.475, 31.900047),
			Pnt3(-30.29999, -0.074999996, -35.599953), Pnt3(33.000008, -0.074999996, -35.599953),
            Pnt3(-30.29999, 89.475, -35.599953), Pnt3(33.000008, 89.475, -35.599953)
        ], indices, nothing, nothing, nothing, nothing, nothing)
        push!(primitives, Primitive(tri, nothing, nothing, explosion_mi))
        # push!(primitives, Primitive(tri, "mat_gray", nothing))
    end

    disk_t = Transformation(Mat4(1000, 0, 0, 0, 0, 1000, 0, 0, 0, 0, 1000, 0, 0, -0.05, 0, 1)) * 
        Transformation(Mat4(1, 0, 0, 0, 0, 0, -1, 0, 0, 1, 0, 0, 0, 0, 0, 1))

    disk = Disk(disk_t, 0.0, 1.0, 0.0, 360.0, false, false)
    push!(primitives, Primitive(disk, "mat_gray", nothing))

    print("\nThere are " * num2str(length(primitives)) * " objects in the scene, building BVH\n")
    @time bvh = BVH(primitives)
    print("Done building BVH\n")

    # Infinite light — low sun env map
    light_t = Transformation(Mat4(-0.9848077, -0.015134436, -0.17298739, 0, 0, 0.9961947, -0.087155744, 0, 0.17364818, -0.08583165, -0.98106027, 0, 0, 0, 0, 1)) *
        Scale(1.0, 1.0, -1.0) *
        Rotate(90.0, Vec3(0, 0, 1)) *
        Rotate(90.0, Vec3(0, 1, 0))
    light = InfiniteLight(
        world_bounds(bvh),
        light_t,
        spectrum_from_float(2.0, Illuminant),
        jmfp("/Users/johnmyslinski/Documents/pbrt-v4-volumes/scenes/ground_explosion/env/low_sun.exr"),
        true
    )
    push!(lights, light)

    filter = BoxFilter(Pnt2(0.5, 0.5))
    film = Film(
        Pnt2i(parsed_args["image-dim"][1], parsed_args["image-dim"][2]),
        Bounds2(Pnt2(parsed_args["crop-window"][1], parsed_args["crop-window"][2]), Pnt2(parsed_args["crop-window"][3], parsed_args["crop-window"][4])),
        filter,
        1.0,
        1.0,
        parsed_args["file-name"]
    )

    # Camera: positioned to match pbrt's transform — above and back, looking at explosion center
    camera_t = Inv(Transformation(Mat4(1, 0, 0, 0, 0, 0.99254614, 0.12186934, 0, 0, 0.12186934, -0.99254614, 0, 0, -35.430065, 247.52719, 1)))
    screen_window = Bounds2(Pnt2(-1, -0.75), Pnt2(1, 0.75))
    C = PerspectiveCamera(camera_t, screen_window, 0.0, 1.0, 0.0, 1e6, 45.0, film)

    S = ZSobolSampler(
        parsed_args["samples-per-pixel"],
        Pnt2i(parsed_args["image-dim"][1], parsed_args["image-dim"][2]),
        Int8(2),
        parsed_args["seed"]
    )
    print("Using " * num2str(S.samples_per_pixel) * " samples per pixel\n")

    print("There are " * num2str(length(lights)) * " lights in the scene\n")
    scene = Scene(lights, bvh)

    I = VolPathIntegratorv3(C, S, parsed_args["max-depth"])

    return I, scene
end

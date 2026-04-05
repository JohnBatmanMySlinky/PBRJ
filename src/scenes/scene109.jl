"""
requires the cow.obj from here
https://github.com/Libbum/spherical-cow#
"""
function make_scene109(parsed_args::Dict)::Tuple{AbstractIntegrator, Scene}
    primitives = Primitive[]
    lights = Light[]
    materials = Material[]

    mat_gray = Matte(
        "mat_gray",
        ConstantTexture(spectrum_from_float(0.5, 0.5, 0.5)),
        ConstantTexture(0.0),
        nothing
    )
    push!(materials, mat_gray)

    sc = ShapeCore()
    triangles = RayTracing.parse_obj(
        jmfp("/home/jmyslinski/random_stuff/spherical-cow/examples/objects/cow.obj"),
        RayTracing.Translate(RayTracing.Pnt3(0, 0, 0)),
        false,
        false,
        nothing
    )
    for tris in triangles
        voxel_bounds = voxelize_to_bounds(tris, 0.125)
        for voxel_bound in voxel_bounds
            voxel_tris = Box(sc, voxel_bound.pMin, voxel_bound.pMax, "mat_gray")
            for voxel_tri in voxel_tris
                push!(primitives, voxel_tri)
            end
        end
    end


    name_index = Dict(mat.name => i for (i, mat) in enumerate(materials))
    MATERIAL_REGISTRY[] = MaterialRegistry(materials, name_index)

    # instantiate accelerator
    print("\nThere are " * num2str(length(primitives)) * " objects in the scene, building BVH\n")
    @time bvh = BVH(primitives)
    print("Done building BVH\n")

    l_2_w_matrix = Mat4([-0.224951, 0.0, -0.97437, 0.0, -0.97437, 0.0, 0.224951, 0.0, 0.0, 1.0, 0.0, 8.87, 0.0, 0.0, 0.0, 1.0])
    l_2_w = Transformation(l_2_w_matrix, inv(l_2_w_matrix))
    light = InfiniteLight(
        world_bounds(bvh),
        l_2_w,
        spectrum_from_float(1.0),
        jmfp("/Users/johnmyslinski/Documents/pbrt-v3-scenes/sssdragon/textures/envmap.exr"),
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
    look_from = Pnt3(11.0, 7.0, 11.0)
    look_at = centroid(world_bounds(bvh))
    up = Vec3(0, 1, 0)
    C = PerspectiveCamera(LookAt(look_from, look_at, up) * Scale(-1.0, 1.0, 1.0), nothing, 0.0, 1.0, 0.0, 1e6, 37.0, film)

    # Instantiate a Sampler
    S = SamplerFactory(parsed_args)
    print("Using " * num2str(S.samples_per_pixel) * " samples per pixel\n")
    
    # Instantiate Scene
    print("There are " * num2str(length(lights)) * " lights in the scene\n")
    scene = Scene(lights, bvh)
    
    # Instantiate an Integrator
    I = VolPathIntegratorv3(C, S, parsed_args["max-depth"])

    return I, scene
end

include("../src/RayTracing.jl")

using Test

# parse command line args
parsed_args = RayTracing.parse_commandline()
parsed_args["scene-number"] = 4

# build scene
I, scene = RayTracing.build_scene(parsed_args)

################
### Begin Tests
################

# test properties of intersection
@testset "Cornell Box - Wall Intersection & Light Sampling Testing" begin
    camera_pnt = I.camera.core.core.camera_to_world(RayTracing.Pnt3(0, 0, 0)) # start from camera
    
    # FLOOR TESTING
    target_pnt = RayTracing.Pnt3(278, 0, 5) # pick a point on the floor to intersect with
    test_ray = RayTracing.Ray(
        camera_pnt,
        target_pnt-camera_pnt,
        0,
        typemax(Float64)
    )
    check, t, intersection = RayTracing.intersect!(scene.b, test_ray)
    @test intersection.core.p ≈ target_pnt
    @test intersection.core.n ≈ [0.0, 1.0, 0.0]
    @test intersection.shading.n ≈ [0.0, 1.0, 0.0]

    sampled_li, wi, pdf, vis, pshape, nshape = RayTracing.sample_li(scene.lights[1], intersection.core, RayTracing.Pnt2(0.5, 0.5))
    @test RayTracing.dot(nshape, -wi) > 0
    @test sampled_li ≈ [500000.0, 500000.0, 500000.0]
    @test wi ≈ RayTracing.normalize(pshape - intersection.core.p)
    @test nshape ≈ [0.0, -1.0, 0.0]

    # LEFT TESTING
    target_pnt = RayTracing.Pnt3(0, 278, 5)
    test_ray = RayTracing.Ray(
        camera_pnt,
        target_pnt-camera_pnt,
        0,
        typemax(Float64)
    )
    check, t, intersection = RayTracing.intersect!(scene.b, test_ray)
    @test intersection.core.p ≈ target_pnt
    @test intersection.core.n ≈ [1.0, 0.0, 0.0]
    @test intersection.shading.n ≈ [1.0, 0.0, 0.0]

    sampled_li, wi, pdf, vis, pshape, nshape = RayTracing.sample_li(scene.lights[1], intersection.core, RayTracing.Pnt2(0.5, 0.5))
    @test RayTracing.dot(nshape, -wi) > 0
    @test sampled_li ≈ [500000.0, 500000.0, 500000.0]
    @test wi ≈ RayTracing.normalize(pshape - intersection.core.p)
    @test nshape ≈ [0.0, -1.0, 0.0]

    # RIGHT TESTING
    target_pnt = RayTracing.Pnt3(555, 278, 5)
    test_ray = RayTracing.Ray(
        camera_pnt,
        target_pnt-camera_pnt,
        0,
        typemax(Float64)
    )
    check, t, intersection = RayTracing.intersect!(scene.b, test_ray)
    @test intersection.core.p ≈ target_pnt
    @test intersection.core.n ≈ [-1.0, 0.0, 0.0]
    @test intersection.shading.n ≈ [-1.0, 0.0, 0.0]

    sampled_li, wi, pdf, vis, pshape, nshape = RayTracing.sample_li(scene.lights[1], intersection.core, RayTracing.Pnt2(0.5, 0.5))
    @test RayTracing.dot(nshape, -wi) > 0
    @test sampled_li ≈ [500000.0, 500000.0, 500000.0]
    @test wi ≈ RayTracing.normalize(pshape - intersection.core.p)
    @test nshape ≈ [0.0, -1.0, 0.0]

    # CEILING TESTING
    target_pnt = RayTracing.Pnt3(278, 555, 5)
    test_ray = RayTracing.Ray(
        camera_pnt,
        target_pnt-camera_pnt,
        0,
        typemax(Float64)
    )
    check, t, intersection = RayTracing.intersect!(scene.b, test_ray)
    @test intersection.core.p ≈ target_pnt
    @test intersection.core.n ≈ [0.0, -1.0, 0.0]
    @test intersection.shading.n ≈ [0.0, -1.0, 0.0]

    sampled_li, wi, pdf, vis, pshape, nshape = RayTracing.sample_li(scene.lights[1], intersection.core, RayTracing.Pnt2(0.5, 0.5))
    @test RayTracing.dot(nshape, -wi) < 0
    @test sampled_li ≈ [0.0, 0.0, 0.0]
    @test wi ≈ RayTracing.normalize(pshape - intersection.core.p)
    @test nshape ≈ [0.0, -1.0, 0.0]
end

@testset "BDPT Integrator Testing" begin
    #re-setup
    I, scene = RayTracing.build_scene(parsed_args)

    # setup
    RayTracing.Random.seed!(5) # 4 was good
    light_distr_generator = RayTracing.LightDistribution("uniform", scene)
    pixel = RayTracing.Pnt2(241, 113)
    camera_sample = RayTracing.get_camera_sample!(I.sampler, pixel)

    # instantiate the list of vertices
    camera_vertices = Vector{RayTracing.Vertex}(undef, I.max_depth + 2)
    light_vertices = Vector{RayTracing.Vertex}(undef, I.max_depth + 1)

    # Trace the camera and light subpaths
    n_camera = RayTracing.generate_camera_subpath!(
        camera_vertices,
        scene, 
        I.sampler, 
        I.max_depth + 2, 
        I.camera,
        camera_sample, 
    )
    
    light_distr = RayTracing.lookup(light_distr_generator, RayTracing.p(camera_vertices[1]))
    n_light, light_num = RayTracing.generate_light_subpath!(
        light_vertices,
        scene,
        I.sampler,
        I.max_depth + 1,
        RayTracing.time(camera_vertices[1]),
        light_distr
    )
    print("max depth: $(I.max_depth), nlight: $(n_light), ncamera: $(n_camera)\n")
    print("Camera Vertices:\n")
    RayTracing.print_nice(camera_vertices)
    print("\nLight Vertices:\n")
    RayTracing.print_nice(light_vertices)

    # AIGHT NOW LETS CONNECT STUFF
    print("\nConnecting Stuff\n")
    L = RayTracing.Spectrum(0.0)
    for t in 1:n_camera
        for s in 0:n_light
            depth = t + s - 2
            print("\n  s: $(s), t: $(t), depth: $(depth)\n")
            if (((s==1)&&(t==1)) || (depth<0) || (depth>I.max_depth))
                print("    early exit\n")
                continue
            end

            mis_weight = 0.0
            L_path, mis_weight, p_film_new = RayTracing.connect_BDPT(
                scene,
                light_vertices,
                camera_vertices,
                s,
                t,
                light_distr,
                light_num,
                I.camera,
                I.sampler,
                camera_sample.film
            )

            print("    mis_weight: $(mis_weight)\n")
            if t != 1
                L += L_path
                print("    Final L: $(L)\n")
            else
                RayTracing.add_splat!(I.camera.core.core.film, p_film_new, L_path)
                print("    Splatted L: $(L_path)")
            end
            print("\n")
        end
    end

    # why camera path so short?
        # first draw is [0,0]???
    # figure out add splat, how to log that?
        # why whas I getting some negative splat coords?
    # why are there so many L_path = 0?
    # why light path SOMETIMES go to the ceiling first?
    # I should check that zero L paths should be zero!
    # how to validate MIS WEIGHT
end

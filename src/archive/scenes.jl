struct Universe
    camera::Camera
    world::BVHNode
    lights::Hittable
    background::Vec3
end

function scenes(which::Int64)::Universe
    if which == 1
        ####################
        ##### Cornell Box w/ triangle light and glossy spheres
        ####################

        background = Vec3(0,0,0)

        lookfrom=Vec3(278, 278, -800)
        lookat=Vec3(278, 278, 0)
        vup=Vec3(0,1,0)
        vfov=40.0
        aspect_ratio=1.0
        apeture=0.0
        focus_dist=10.0
        time0 = 0.0
        time1 = 1.0

        # camera
        cam = camera(
            lookfrom,
            lookat,
            vup,
            vfov,
            aspect_ratio,
            apeture,
            focus_dist,
            time0, time1
        )

        # hittable list
        red = Lambertian(ConstantTexture(Vec3(.65, .05, .05)))
        white = Lambertian(ConstantTexture(Vec3(.73, .73, .73)))
        green = Lambertian(ConstantTexture(Vec3(.12, .45, .15)))
        blue = Lambertian(ConstantTexture(Vec3(.12, .05, .95)))
        light = DiffuseLight(ConstantTexture(Vec3(15, 15, 15)))
        metal = Metal(Vec3(.8, .85, .88), 0)
        glass = Dielectric(1.5)
        pn = Lambertian(PerlinNoise())
        plastic = AnisotropicPhong(ConstantTexture(Vec3(.12, .08, .8)), 100, 10)
        plastic2 = AnisotropicPhong(ConstantTexture(Vec3(.8, .08, .4)), 10, 1000)
        plastic3 = AnisotropicPhong(ConstantTexture(Vec3(.1, .78, .2)), 10000, 10000)

        stuff = Hittable[]
        push!(stuff, YZRectangle(0, 555, 0, 555, 555, green))
        push!(stuff, YZRectangle(0, 555, 0, 555, 0, red))
        push!(stuff, Triangle(Vec3(213, 554, 343), Vec3(213, 554, 213), Vec3(343, 554, 213), light))
        push!(stuff, XZRectangle(0, 555, 0, 555, 0, pn))
        push!(stuff, XZRectangle(0, 555, 0, 555, 555, white))
        push!(stuff, XYRectangle(0, 555, 0, 555, 555, white))

        box1 = Box(
            Vec3(0, 0, 0),
            Vec3(165, 330, 165),
            metal
        )
        box1 = YRotate(box1, 25.0)
        box1 = Translate(box1, Vec3(265, 0, 295))


        push!(stuff, Sphere(Vec3(125, 330, 380), 90, plastic3))     
        push!(stuff, Sphere(Vec3(350, 200, 150), 90, plastic2))   
        push!(stuff, Sphere(Vec3(190, 90, 190), 90, glass))        

        fin = vcat(
            stuff,
            box1,
        )

        lights = []
        push!(lights, Triangle(Vec3(213, 554, 343), Vec3(213, 554, 213), Vec3(343, 554, 213), light))
        push!(lights, Sphere(Vec3(190, 90, 190), 90, glass))         
        
          

        return Universe(
            cam, 
            construct_bvh(HittableList(fin), 0.0, 1.0),
            HittableList(lights),
            background
        )
    elseif which == 2
        background = Vec3(0, 0, 0)

        lookfrom=Vec3(-5, 10.0, 20)
        lookat=Vec3(10, 4, 0)
        vup=Vec3(0,1,0)
        vfov=40.0
        aspect_ratio=1.0
        apeture=0.0
        focus_dist=10.0
        time0 = 0.0
        time1 = 1.0

        # camera
        cam = camera(
            lookfrom,
            lookat,
            vup,
            vfov,
            aspect_ratio,
            apeture,
            focus_dist,
            time0, time1
        )

        # materials
        red = Lambertian(ConstantTexture(Vec3(.65, .05, .05)))
        white = Lambertian(ConstantTexture(Vec3(.73, .73, .73)))
        green = Lambertian(ConstantTexture(Vec3(.12, .45, .15)))
        light = DiffuseLight(ConstantTexture(Vec3(7, 7, 7)))
        plastic = AnisotropicPhong(ConstantTexture(Vec3(.12, .08, .8)), 5, 500)
        mat_earth = Lambertian(Image(load("earthmap.jpg")))
        metal = Metal(Vec3(.8, .85, .88), 0)
        env_light = DiffuseLight(Image(load("hdr_111_parking_space_2_prev.jpg")))
        epdf = construct_env_pdf(load("hdr_111_parking_space_2_prev.jpg"))
        white_importance = ImportanceLambertian(ConstantTexture(Vec3(.73, .73, .73)), epdf)

        # objects
        floor = XZRectangle(-50, 50, -50, 50, 0, white_importance)
        env_sphere = FlipFace(Sphere(Vec3(0,0,0), 75, env_light))

        # hittable list & light to be sampled list
        stuff = parse_obj("../objs/llama.obj", plastic)
        push!(stuff, floor)
        push!(stuff, env_sphere) 

        lights = Hittable[]

        return Universe(
            cam, 
            construct_bvh(HittableList(stuff), 0.0, 1.0),
            HittableList(lights),
            background
        )
    elseif which == 3
        background = Vec3(0, 0, 0)

        lookfrom=Vec3(-5, 10.0, 20)
        lookat=Vec3(10, 4, 0)
        vup=Vec3(0,1,0)
        vfov=40.0
        aspect_ratio=1.0
        apeture=0.0
        focus_dist=10.0
        time0 = 0.0
        time1 = 1.0

        # camera
        cam = camera(
            lookfrom,
            lookat,
            vup,
            vfov,
            aspect_ratio,
            apeture,
            focus_dist,
            time0, time1
        )

        # materials
        white = Lambertian(ConstantTexture(Vec3(.69, .69, .69)))
        plastic = AnisotropicPhong(ConstantTexture(Vec3(.12, .08, .8)), 5, 500)
        perlin_light = DiffuseLight(PerlinNoise(2.0))

        # objects
        floor = XZRectangle(-50, 50, -50, 50, 0, white)
        perlin_light = XYRectangle(-20, 20, -20, 20, -10, perlin_light)

        # hittable list & light to be sampled list
        stuff = parse_obj("../objs/llama.obj", plastic)
        push!(stuff, floor)
        push!(stuff, perlin_light)

        lights = Hittable[]

        return Universe(
            cam, 
            construct_bvh(HittableList(stuff), 0.0, 1.0),
            HittableList(lights),
            background
        )
    elseif which == 4
        background = Vec3(.8, .8, .8)

        lookfrom=Vec3(10, 6, -3)
        lookat=Vec3(0, 5, -2.5)
        vup=Vec3(0,1,0)
        vfov=50.0
        aspect_ratio=1.0
        apeture=0.0
        focus_dist=10.0
        time0 = 0.0
        time1 = 1.0

        # camera
        cam = camera(
            lookfrom,
            lookat,
            vup,
            vfov,
            aspect_ratio,
            apeture,
            focus_dist,
            time0, time1
        )

        # materials
        matte_dark_blue = Lambertian(ConstantTexture(Vec3(79.0/255, 101.0/255, 113.0/255)))
        matte_red = Lambertian(ConstantTexture(Vec3(166.0/255, 10.0/255, 61.0/255)))
        matte_green = Lambertian(ConstantTexture(Vec3(1.0/255, 115.0/255, 92.0/255)))
        matte_light_gray = Lambertian(ConstantTexture(Vec3(.75, .85, .8)))
        light1 = DiffuseLight(ConstantTexture(Vec3(25, 25, 25)))
        light2 = DiffuseLight(ConstantTexture(Vec3(25, 25, 25)))
        glass = Dielectric(1.5)


        # objects
        lamp_light = Sphere(Vec3(-3, 6.75, 0), .25, light1)
        lamp_cone = Translate(Rotate(Cone(1.5, 2, 2pi, matte_light_gray), Vec3(90, 0, 0)), Vec3(-3, 6, 0))
        lamp_pole = Translate(CappedCylinder(0.0, 6.0, .15, 2pi, matte_light_gray), Vec3(-3, 0, 0))
        lamp_base = Translate(Rotate(Cone(1, .5, 2pi, matte_light_gray), Vec3(270, 0, 0)), Vec3(-3, 0, 0))

        table_top = Box(Vec3(-4, 2.5, -7), Vec3(-2, 2.75, -2), matte_light_gray)
        table_leg1 = Translate(CappedCylinder(0.0, 2.5, .15, 2pi, matte_light_gray), Vec3(-3.75, 0, -2.25))
        table_leg2 = Translate(CappedCylinder(0.0, 2.5, .15, 2pi, matte_light_gray), Vec3(-2.25, 0, -2.25))
        table_leg3 = Translate(CappedCylinder(0.0, 2.5, .15, 2pi, matte_light_gray), Vec3(-3.75, 0, -6.75))
        table_leg4 = Translate(CappedCylinder(0.0, 2.5, .15, 2pi, matte_light_gray), Vec3(-2.25, 0, -6.75))

        table_thing = Translate(Ellipsoid(Vec3(.5, 1, .5), glass), Vec3(-2.5, 3.25, -3))

        floating_light_tube = Translate(Rotate(CappedCylinder(0, 1.25, .5, 2pi, matte_light_gray), Vec3(-65, 0, 0)), Vec3(-3, 5, -6))
        floating_light = Sphere(Vec3(-3, 5, -6), .35, light2)

        left_wall = XYRectangle(-10, 10, 0, 10, 2, matte_red)
        right_wall = XYRectangle(-10, 10, 0, 10, -8, matte_green)
        back_wall = YZRectangle(-10, 10, -10, 10, -8, matte_light_gray)
        floor = XZRectangle(-50, 50, -50, 50, 0, matte_dark_blue)
        ceiling = XZRectangle(-50, 50, -50, 50, 8, matte_dark_blue)

        # hittable list & light to be sampled list
        stuff = Hittable[]
        push!(stuff, lamp_light)
        push!(stuff, lamp_cone)
        push!(stuff, lamp_pole)
        push!(stuff, lamp_base)

        push!(stuff, table_leg1)
        push!(stuff, table_leg2)
        push!(stuff, table_leg3)
        push!(stuff, table_leg4)

        push!(stuff, table_thing)

        push!(stuff, floating_light_tube)
        push!(stuff, floating_light)

        push!(stuff, left_wall)
        push!(stuff, right_wall)
        push!(stuff, back_wall)
        push!(stuff, floor)
        push!(stuff, ceiling)

        fin = vcat(stuff, table_top)

        lights = Hittable[]
        push!(lights, floating_light)
        push!(lights, lamp_light)

        return Universe(
            cam, 
            construct_bvh(HittableList(fin), 0.0, 1.0),
            HittableList(lights),
            background
        )

    elseif which == 7
        ####################
        ##### teapot!
        ####################

        background = Vec3(0, 0, 0)

        lookfrom=Vec3(175, 225, 335)
        lookat=Vec3(0, 2, 0)
        vup=Vec3(0,1,0)
        vfov=30.0
        aspect_ratio=3.0/2.0
        apeture=0.0
        focus_dist=10.0
        time0 = 0.0
        time1 = 1.0

        # camera
        cam = camera(
            lookfrom,
            lookat,
            vup,
            vfov,
            aspect_ratio,
            apeture,
            focus_dist,
            time0, time1
        )

        # hittable list
        mat_gray = Lambertian(ConstantTexture(Vec3(.5, .5, .5)))
        mat_red = Lambertian(ConstantTexture(Vec3(.9, .2, .3)))
        mat_blue = Lambertian(ConstantTexture(Vec3(.6, .2, .8)))
        mat_light = DiffuseLight(ConstantTexture(Vec3(4.0, 4.0, 4.0)))

        stuff = parse_obj("../objs/teapot.obj", mat_blue)
        push!(stuff, XZRectangle(-1000, 1000, -1000, 1000, -57, mat_gray))
        push!(stuff, XYRectangle(0, 100, 0, 100, -150, mat_light))
        # push!(stuff, Sphere(Vec3(0, 0, -150), 25, mat_red))


        return Universe(
            cam, 
            construct_bvh(HittableList(stuff), 0.0, 1.0),
            background
        )
    end
end
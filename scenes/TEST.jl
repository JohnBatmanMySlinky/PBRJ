using RayTracing

function render()
    material_matte = RayTracing.MatteMaterial(ConstantTexture(Vec3(.8, .8, .8)))

    transform_move_right = Translate(Vec3(5, 0, 0))
    sphere_right = Sphere(
        ShapeCore(
            transform_move_right,      # object_to_world
            Inv(transform_move_right)  # world_to_object
        ),
        5.0,                        # radius
        0.0,                        # zMin
        5.0,                        # zMax
        0.0,                        # thetaMin
        2pi,                        # thetaMax
        2pi                         # phiMax
    )
    primitive1 = Primitive(sphere_right, material_matte)


    
    transform_move_left = Translate(Vec3(-5, 0, 0))
    sphere_righ2 = Sphere(
        ShapeCore(
            transform_move_left,      # object_to_world
            Inv(transform_move_left)  # world_to_object
        ),
        5.0,                        # radius
        0.0,                        # zMin
        5.0,                        # zMax
        0.0,                        # thetaMin
        2pi,                        # thetaMax
        2pi                         # phiMax
    )
    primitive2 = Primitive(sphere_left, material_matte)

    all_primitives = [primitive1, primitive2]
    bvh = ConstructBVH(all_primitives)

    from, to = Vec3(0, 20, 0), Vec3(-5, 0, 5)
    cone_angle, cone_delta_angle = 30, 10
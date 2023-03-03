include("../src/RayTracing.jl")

# parse command line args
parsed_args = RayTracing.parse_commandline()
parsed_args["scene-number"] = 4

# build scene
I, scene = RayTracing.build_scene(parsed_args)

camera_pnt = I.camera.core.core.camera_to_world(RayTracing.Pnt3(0, 0, 0))
target_pnt = RayTracing.Pnt3(278, 0, 278)
test_ray = RayTracing.Ray(
    camera_pnt,
    target_pnt-camera_pnt,
    0,
    typemax(Float64)
)
check, t, intersection = RayTracing.intersect!(scene.b, test_ray)

print(intersection)

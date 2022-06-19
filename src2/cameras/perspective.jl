# PBR 6.2.2
struct PerspectiveCamera <: Camera
    core::ProjectiveCamera
    A::Float32

    function PerspectiveCamera(
        camera_to_world::Transformation,
        screen_window::Bounds2,
        shutter_open::Float64,
        shutter_closed::Float64,
        lens_radius::Float64,
        focal_distance::Float64,
        fov::Float64,
        film::Film
    )
        projcam = ProjectiveCamera(
            camera_to_world,
            perspective(fov, .01, 1000),
            screen_window,
            shutter_open,
            shutter_closed,
            lens_radius,
            focal_distance,
            film
        )
        p_min = projcam.raster_to_camera(Vec3(0,0,0))
        p_max = projcam.raster_to_camera(film.resolution[1], film.resolution[2], 0)
        p = p_min[1:2] ./ p_min[3] - p_max[1:2] ./ p_max[3]
        A = abs(p[1] * p[2])
        new(projcam, A)
    end
end

#########################################
## Generate Ray for Perspective Camera ##
#########################################

function generate_ray(camera::PerspectiveCamera, sample::CameraSample)::Tuple{Ray, Float64}
    p_film = Vec3(sample.film[1], sample.film[2], 0)
    p_camera = camera.core.raster_to_camera(p_film)

    r = Ray(Vec3(0, 0, 0), normalize(Vec3(p_camera, p_camera, p_camera)), 0, typemax(Float64))
    if camera.core.lens_radius > 0
        p_lens = camera.core.lens_radius * random_in_concentric_disk(camera.lens)
        t = camera.core.focal_distance / r.direction[3]
        p_focus = at(r, t)
        ray.origin = Vec3(p_lens[1], p_lens[2], 0)
        ray.direciton = normalize(Vec3(p_focus - ray.origin))
    end

    ray.time = lerp(
        camera.core.core.shutter_open,
        camera.core.core.shutter_closed,
        sample.time
    )
    ray = camera.core.core.camera_to_world(core)
    ray.direciton = normalize(ray.direction)
    return ray, 1
end
###########################
### Projective Camera #####
###########################

# PBR 6.2
# "Therefore, we will introduce a projection matrix camera class, ProjectiveCamera, and then define two camera models based on it."
# "The first implements an orthographic projection, and the other implements a perspective projection"
struct ProjectiveCamera <: Camera
    core::CameraCore
    camera_to_screen::Transformation
    raster_to_camera::Transformation
    screen_to_raster::Transformation
    raster_to_screen::Transformation
    lens_radius::Float64
    focal_distance::Float64

    function ProjectiveCamera(
        camera_to_world::Transformation,
        camera_to_screen::Transformation,
        screen_window::Bounds2,
        shutter_open::Float64,
        shutter_closed::Float64,
        lens_radius::Float64,
        focal_distance::Float64,
        film::Film
    )
        core = CameraCore(camera_to_world, shutter_open, shutter_closed, film)
        screen_to_raster = (
            Scale(Vec3(
                film.full_resolution[1],
                film.full_resolution[2], 
                1
            )) * Scale(Vec3(
                1 / (screen_window.pMax[1] - screen_window.pMin[1]),
                1 / (screen_window.pMax[2] - screen_window.pMin[2]),
                1
            )) * Translate(Vec3(
                -screen_window.pMin[1],
                -screen_window.pMax[2],
                0
            ))
        )
        raster_to_screen = Inv(screen_to_raster)
        raster_to_camera = Inv(camera_to_screen) * raster_to_screen

        new(
            core,
            camera_to_screen,
            raster_to_camera,
            screen_to_raster,
            raster_to_screen,
            lens_radius,
            focal_distance
        )
    end
end


###########################
### Perspective Camera ####
###########################

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
            Perspective(fov, .01, 1000.0),
            screen_window,
            shutter_open,
            shutter_closed,
            lens_radius,
            focal_distance,
            film
        )
        p_min = projcam.raster_to_camera(Pnt3(0,0,0))
        p_max = projcam.raster_to_camera(Pnt3(film.full_resolution[1], film.full_resolution[2], 0))
        p_min /= p_min[3]
        p_max /= p_max[3]
        A = abs((p_max[1] - p_min[1])*(p_max[2] - p_min[2]))
        new(projcam, A)
    end
end

#########################################
## Generate Ray for Perspective Camera ##
#########################################

function generate_ray(camera::PerspectiveCamera, sample::CameraSample)::Tuple{Ray, Float64}
    p_film = Pnt3(sample.film[1], sample.film[2], 0)
    p_camera = normalize(camera.core.raster_to_camera(p_film))

    ray = Ray(Pnt3(0, 0, 0), Vec3(p_camera[1], p_camera[2], p_camera[3]), 0, typemax(Float64))
    if camera.core.lens_radius > 0
        p_lens = camera.core.lens_radius .* random_in_concentric_disk(sample.lens)
        t = camera.core.focal_distance / ray.direction[3]
        p_focus = at(ray, t)
        ray.origin = Pnt3(p_lens[1], p_lens[2], 0)
        ray.direciton = normalize(Vec3(p_focus - ray.origin))
    end    

    ray.time = lerp(
        sample.time,
        camera.core.core.shutter_open,
        camera.core.core.shutter_closed,
    )
    ray = camera.core.core.camera_to_world(ray)
    ray.direction = normalize(ray.direction)
    return ray, 1.0
end


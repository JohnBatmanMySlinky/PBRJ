# PBR 6.2
struct ProjectiveCamera <: Camera
    core::CameraCore
    camera_to_screen::Transformations
    raster_to_camera::Transformations
    screen_to_raster::Transformations
    raster_to_screen::Transformations
    lens_radius::Float64
    focal_distance::Float64

    function ProjectiveCamera(
        camera_to_world::Transformations,
        camera_to_screen::Transformations,
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
                flm.resolution[1],
                film.resolution[2], 
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


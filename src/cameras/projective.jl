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
        film::Union{Film, PassFilm}
    )
        core = CameraCore(camera_to_world, shutter_open, shutter_closed, film)
        screen_to_raster = (
            Scale(
                Vec3(film.full_resolution.x, film.full_resolution.y, 1)
            ) * Scale(
                Vec3(1 / (screen_window.pMax.x - screen_window.pMin.x), 1 / (screen_window.pMin.y - screen_window.pMax.y), 1)
            ) * Translate(
                Vec3(-screen_window.pMin.x, -screen_window.pMax.y, 0)
            )  
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
    dx_camera::Pnt3
    dy_camera::Pnt3
    A::Float64

    function PerspectiveCamera(
        camera_to_world::Transformation,
        screen_window::Bounds2,
        shutter_open::Float64,
        shutter_closed::Float64,
        lens_radius::Float64,
        focal_distance::Float64,
        fov::Float64,
        film::Union{Film, PassFilm}
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
        dx_camera = projcam.raster_to_camera(Pnt3(1,0,0)) - projcam.raster_to_camera(Pnt3(0))
        dy_camera = projcam.raster_to_camera(Pnt3(0,1,0)) - projcam.raster_to_camera(Pnt3(0))

        p_min = projcam.raster_to_camera(Pnt3(0))
        p_max = projcam.raster_to_camera(Pnt3(film.full_resolution.x, film.full_resolution.y, 0))
        p_min /= p_min.z
        p_max /= p_max.z
        A = abs((p_max.x - p_min.x)*(p_max.y - p_min.y))
        new(projcam, dx_camera, dy_camera, A)
    end
end

#########################################
## Generate Ray for Perspective Camera ##
#########################################

function generate_ray(camera::PerspectiveCamera, sample::CameraSample)::Tuple{Ray, Float64}
    p_film = Pnt3(sample.film.x, sample.film.y, 0)
    p_camera = camera.core.raster_to_camera(p_film)

    ray = Ray(Pnt3(0), normalize(Vec3(p_camera)), 0, typemax(Float64))
    @info "p_film: $(p_film), p_camera: $(p_camera), ray: $(ray)"
    if camera.core.lens_radius > 0
        p_lens = camera.core.lens_radius .* random_in_concentric_disk(sample.lens)
        t = camera.core.focal_distance / ray.direction.z
        p_focus = at(ray, t)
        ray.origin = Pnt3(p_lens.x, p_lens.y, 0)
        ray.direciton = normalize(Vec3(p_focus - ray.origin))
    end    

    ray.t = lerp(
        sample.t,
        camera.core.core.shutter_open,
        camera.core.core.shutter_closed,
    )
    ray = camera.core.core.camera_to_world(ray)
    return ray, 1.0
end

function generate_ray_differential(camera::PerspectiveCamera, sample::CameraSample)::Tuple{RayDifferential, Float64}
    p_film = Pnt3(sample.film.x, sample.film.y, 0)
    p_camera = camera.core.raster_to_camera(p_film)
    ray = RayDifferential(Ray(Pnt3(0), normalize(Vec3(p_camera)), 0.0, typemax(Float64)))
    @info "p_film: $(p_film), p_camera: $(p_camera), ray: $(ray)"

    if camera.core.lens_radius > 0
        p_lens = camera.core.lens_radius .* random_in_concentric_disk(sample.lens)
        t = camera.core.focal_distance / ray.direction.z
        p_focus = at(ray, t)
        ray.origin = Pnt3(p_lens.x, p_lens.y, 0)
        ray.direciton = normalize(Vec3(p_focus - ray.origin))

        dx = normalize(Vec3(p_camera + camera.dx_camera))
        pfocus = Pnt3(0) + (t * dx)
        ray.rx_origin = Pnt3(p_lens.x, p_lens.y, 0)
        ray.rx_direction = normalize(pfocus - ray.rx_origin)

        dy = normalize(Vec3(p_camera + camera.dy_camera))
        pfocus = Pnt3(0) + (t * dy)
        ray.ry_origin = Pnt3(p_lens.x, p_lens.y, 0)
        ray.ry_direction = normalize(pfocus - ray.ry_origin)
    else
        ray.rx_origin = ray.origin
        ray.ry_origin = ray.origin
        ray.rx_direction = normalize(Vec3(p_camera) + camera.dx_camera)
        ray.rx_direction = normalize(Vec3(p_camera) + camera.dy_camera)
    end

    ray.t = lerp(
        sample.t,
        camera.core.core.shutter_open,
        camera.core.core.shutter_closed,
    )
    ray = camera.core.core.camera_to_world(ray)
    return ray, 1.0
end

#########################################
######## 16.1.1 Sampling Cameras ########
#########################################

function we(camera::PerspectiveCamera, ray::AbstractRay)::Tuple{Spectrum, Pnt2}
    # interpolate camera matrix and check if w is forward facing
    # JOHN HACK no interpolation
    cos_theta = dot(ray.direction, camera.core.core.camera_to_world(Vec3(0,0,1)))
    (cos_theta <= 0) && return spectrum_from_float(0.0), Pnt2(0, 0)

    # map ray (p,w) onto the raster grid
    p_focus = at(ray, (camera.core.lens_radius > 0 ? camera.core.focal_distance : 1) / cos_theta)
    p_raster = Inv(camera.core.raster_to_camera)(Inv(camera.core.core.camera_to_world)(p_focus))

    # return raster position if requested
    p_raster2 = Pnt2(p_raster.x, p_raster.y)

    # return zero importance for out of bound points
    sample_bounds = get_sample_bounds(camera.core.core.film)
    if (p_raster.x < sample_bounds.pMin.x) || (p_raster.x >= sample_bounds.pMax.x) || (p_raster.y < sample_bounds.pMin.y) || (p_raster.y >= sample_bounds.pMax.y)
        return spectrum_from_float(0.0), p_raster2
    end
    
    # compute lens area of perspective camera
    lens_area = camera.core.lens_radius != 0 ? (pi * camera.core.lens_radius ^ 2) : 1.0

    # return importance for point on image plane
    return spectrum_from_float(1.0/(camera.A * lens_area * cos_theta ^ 4)), p_raster2
end

function pdf_we(camera::PerspectiveCamera, ray::AbstractRay)::Tuple{Float64, Float64}
    # interpolate camera matrix and fail if w is not forward-facing
    cos_theta = dot(ray.direction, camera.core.core.camera_to_world(Vec3(0,0,1)))
    (cos_theta <= 0) && return 0.0, 0.0

    # map ray (p,w) onto the raster grid
    p_focus = at(ray,(camera.core.lens_radius > 0 ? camera.core.focal_distance : 1) / cos_theta)
    p_raster = Inv(camera.core.raster_to_camera)(Inv(camera.core.core.camera_to_world)(p_focus))

    # return 0 for out of bounds points
    sample_bounds = get_sample_bounds(camera.core.core.film)
    if (p_raster.x < sample_bounds.pMin.x) || (p_raster.x >= sample_bounds.pMax.x) || (p_raster.y < sample_bounds.pMin.y) || (p_raster.y >= sample_bounds.pMax.y)
        return 0.0, 0.0
    end

    # compute lens area of perspective camera
    lens_area = camera.core.lens_radius != 0 ? (pi * camera.core.lens_radius ^ 2) : 1.0

    # pdf_pos, pdf_dir
    return 1 / lens_area, 1 / (camera.A * cos_theta ^ 3)
end
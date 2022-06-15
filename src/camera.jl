struct Camera
    aspect_ratio::Float64
    viewport_height::Float64
    viewport_width::Float64
    origin::Vec3
    horizontal::Vec3
    vertical::Vec3
    lower_left_corner::Vec3
    lens_radius::Float64
    u::Vec3
    v::Vec3
    time0::Float64
    time1::Float64
end

# instantiate a camera
function camera(lookfrom::Vec3, lookat::Vec3, vup::Vec3, vfov::Float64, aspect_ratio::Float64, apeture::Float64, focus_dist::Float64, time0::Float64, time1::Float64)::Camera
    theta = deg2rad(vfov)
    h = tan(theta/2)
    viewport_height = 2.0 * h
    viewport_width = aspect_ratio * viewport_height

    w = unit_vector(lookfrom .- lookat)
    u = unit_vector(cross(vup, w))
    v = cross(w, u)

    horizontal = focus_dist * viewport_width * u
    vertical = focus_dist * viewport_height * v
    lower_left_corner = lookfrom .- horizontal ./ 2 .- vertical ./ 2 - focus_dist .* w

    lens_radius = apeture / 2

    return Camera(
        aspect_ratio,
        viewport_height,
        viewport_width,
        lookfrom,
        horizontal,
        vertical,
        lower_left_corner,
        lens_radius,
        u,
        v,
        time0,
        time1
    )
end

function get_ray(c::Camera, s::Float64, t::Float64)::Ray
    rd = c.lens_radius .* random_in_unit_disk()
    offset = c.u * rd[1] + c.v * rd[2]
    return Ray(
        c.origin .+ offset, 
        c.lower_left_corner .+ s .* c.horizontal + t .* c.vertical .- c.origin .- offset,
        rand_between(c.time0, c.time1)
    )
end
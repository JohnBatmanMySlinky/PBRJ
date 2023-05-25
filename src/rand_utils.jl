function random_in_concentric_disk(u::Pnt2)::Pnt2
    offset::Pnt2 = 2.0 .* u - Pnt2(1.0, 1.0)

    if all(offset .== 0.0)
        return Pnt2(0.0, 0.0)
    end

    r::Float64 = 0.0
    theta::Float64 = 0.0
    if abs(offset.x) > abs(offset.y)
        r = offset.x
        theta = (offset.y / offset.x) * pi / 4.0
    else
        r = offset.y
        theta = pi / 2.0 - (offset.x / offset.y) * pi / 4.0
    end
    return Pnt2(cos(theta), sin(theta)) .* r
end

function random_in_cosine_hemisphere(u::Pnt2)::Pnt3
    d = random_in_concentric_disk(u)
    z = sqrt(max(0.0, 1-d.y^2 - d.y^2))
    return Pnt3(d.x, d.y, z)
end

function random_on_sphere(u::Pnt2)::Pnt3
    z = 1.0 - 2.0 * u.x
    r = sqrt(max(0, 1-z^2))
    phi = 2 * pi * u.y
    return Vec3(r *cos(phi), r*sin(phi), z)
end

function cosine_sample_hemisphere(u::Pnt2)::Vec3
    d = random_in_concentric_disk(u)
    z = sqrt(max(0.0 ,1-d.x^2-d.y^2))
    return Vec3(d.x, d.y, z)
end

function uniform_sample_cone(u1::Pnt2, cos_theta_max::Float64)::Vec3
    cos_theta = 1.0 - u1.x + u1.x * cos_theta_max
    sin_theta = sqrt(1.0-cos_theta^2)
    phi = u1.y * 2.0 * pi
    return Vec3(cos(phi)*sin_theta, sin(phi)*sin_theta, cos_theta)
end

function cosine_hemisphere_pdf(cos_theta::Float64)::Float64
    return cos_theta / pi
end

function uniform_cone_pdf(cos_theta_max::Float64)::Float64
    return 1.0 / (2.0 * pi * (1-cos_theta_max))
end
function random_in_concentric_disk(u::Pnt2)::Pnt2
    offset = 2 * u - Pnt2(1,1)

    if offset[1] == 0 && offset[2] == 0
        return Pnt2(0,0)
    end

    if abs(offset[1]) > abs(offset[2])
        r = offset[1]
        theta = (offset[2] / offset[1]) * pi / 4
    else
        r = offset[2]
        theta = pi / 2 - (offset[1] / offset[2]) * pi / 4
    end
    return Pnt2(cos(theta), sin(theta)) .* r
end

function random_in_cosine_hemisphere(u::Pnt2)::Pnt3
    d = random_in_concentric_disk(u)
    z = sqrt(max(0, 1-d[2]^2 - d[2]^2))
    return Pnt3(d[1], d[2], z)
end

function random_on_sphere(u::Pnt2)::Pnt3
    z = 1 - 2 * u[1]
    r = sqrt(max(0, 1-z^2))
    phi = 2 * pi * u[2]
    return Vec3(r *cos(phi), r*sin(phi), z)
end

function cosine_sample_hemisphere(u::Pnt2)::Vec3
    d = random_in_concentric_disk(u)
    z = sqrt(max(0,1-d.x^2-d.y^2))
    return Vec3(d.x, d.y, z)
end

function uniform_sample_cone(u1::Pnt2, cos_theta_max::Float64)::Vec3
    cos_theta = 1.0 - u1.x + u1.x * cos_theta_max
    sin_theta = sqrt(1.0-cos_theta^2)
    phi = u1.y * 2 * pi
    return Vec3(cos(phi)*sin_theta, sin(phi)*sin_theta, cos_theta)
end

function shuffle!(samp::Vector, cnt::Int64, n_dimensions::Int64)
    for i = 1:cnt
        other = i + rand(0:(cnt-i))
        for j = 0:(n_dimensions-1)
            # JOHN HACK!
            a = samp[n_dimensions * i + j]
            b = samp[n_dimensions * other + j]
            samp[n_dimensions * i + j] = b
            samp[n_dimensions * other + j] = a
        end
    end
end

function cosine_hemisphere_pdf(cos_theta::Float64)::Float64
    return cos_theta / pi
end

function uniform_cone_pdf(cos_theta_max::Float64)::Float64
    return 1.0 / (2 * pi * (1-cos_theta_max))
end
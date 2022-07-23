function random_in_concentric_disk(p::Pnt2)::Pnt2
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
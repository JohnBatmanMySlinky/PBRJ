function random_in_concentric_disk(p::Vec2)::Vec2
    offset = 2 * u - Vec2(1,1)

    if offset[1] == 0 && offset[2] == 0
        return Vec2(0,0)
    end

    if abs(offset[1]) > abs(offset[2])
        r = offset[1]
        theta = (offset[2] / offset[1]) * pi / 4
    else
        r = offset[2]
        theta = pi / 2 - (offset[1] / offset[2]) * pi / 4
    end
    return Vec2(cos(theta), sin(theta)) .* r
end

function random_in_cosine_hemisphere(u::Vec2)::Vec3
    d = random_in_concentric_disk(u)
    z = sqrt(max(0, 1-d[2]^2 - d[2]^2))
    return Vec3(d[1], d[2], z)
end
struct YZRectangle <: Hittable
    y0::Float64
    y1::Float64
    z0::Float64
    z1::Float64
    k::Float64
    material::Material
end
function bounding_box(yz::YZRectangle, time0::Float64, time1::Float64)::AABB
    output_box = AABB(
        Vec3(yz.k - .0001, yz.y0, yz.z0),
        Vec3(yz.k + .0001, yz.y1, yz.z1)
    )
end
function hit(yz::YZRectangle, r::Ray, t_min::Float64, t_max::Float64)::Option{HitRecord}
    t = (yz.k - r.origin[1]) / r.direction[1]
    if (t < t_min) || (t > t_max)
        return missing
    end

    y = r.origin[2] + t * r.direction[2]
    z = r.origin[3] + t * r.direction[3]
    if (y < yz.y0) || (y > yz.y1) || (z < yz.z0) || (z > yz.z1)
        return missing
    end
    u = (y-yz.y0) / (yz.y1 - yz.y0)
    v = (z-yz.z0) / (yz.z1 - yz.z0)
    p = at(r, t)
    n = Vec3(1, 0, 0)
    if check_face_normal(r, n)
        ff = true
    else
        ff = false
        n = -n
    end
    return HitRecord(t, p, n, yz.material, ff, u, v)
end
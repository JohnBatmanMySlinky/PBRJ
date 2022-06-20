struct XZRectangle <: Hittable
    x0::Float64
    x1::Float64
    z0::Float64
    z1::Float64
    k::Float64
    material::Material
end
function bounding_box(xz::XZRectangle, time0::Float64, time1::Float64)::AABB
    output_box = AABB(
        Vec3(xz.x0, xz.k - .0001, xz.z0),
        Vec3(xz.x1, xz.k + .0001, xz.z1)
    )
end
function hit(xz::XZRectangle, r::Ray, t_min::Float64, t_max::Float64)::Option{HitRecord}
    t = (xz.k - r.origin[2]) / r.direction[2]
    if (t < t_min) || (t > t_max)
        return missing
    end

    x = r.origin[1] + t * r.direction[1]
    z = r.origin[3] + t * r.direction[3]
    if (x < xz.x0) || (x > xz.x1) || (z < xz.z0) || (z > xz.z1)
        return missing
    end
    u = (x-xz.x0) / (xz.x1 - xz.x0)
    v = (z-xz.z0) / (xz.z1 - xz.z0)
    p = at(r, t)
    n = Vec3(0, 1, 0)
    if check_face_normal(r, n)
        ff = true
    else
        ff = false
        n = -n
    end
    return HitRecord(t, p, n, xz.material, ff, u, v)
end
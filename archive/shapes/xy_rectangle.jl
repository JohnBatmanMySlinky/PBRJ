struct XYRectangle <: Hittable
    x0::Float64
    x1::Float64
    y0::Float64
    y1::Float64
    k::Float64
    material::Material
end
function bounding_box(xy::XYRectangle, time0::Float64, time1::Float64)::AABB
    output_box = AABB(
        Vec3(xy.x0, xy.y0, xy.k - .0001),
        Vec3(xy.x1 ,xy.y1, xy.k + .0001)
    )
end
function hit(xy::XYRectangle, r::Ray, t_min::Float64, t_max::Float64)::Option{HitRecord}
    t = (xy.k - r.origin[3]) / r.direction[3]
    if (t < t_min) || (t > t_max)
        return missing
    end

    x = r.origin[1] + t * r.direction[1]
    y = r.origin[2] + t * r.direction[2]
    if (x < xy.x0) || (x > xy.x1) || (y < xy.y0) || (y > xy.y1)
        return missing
    end
    u = (x-xy.x0) / (xy.x1 - xy.x0)
    v = (y-xy.y0) / (xy.y1 - xy.y0)
    p = at(r, t)
    n = Vec3(0, 0, 1)
    if check_face_normal(r, n)
        ff = true
    else
        ff = false
        n = -n
    end
    return HitRecord(t, p, n, xy.material, ff, u, v)
end
struct Ellipsoid <: Hittable
    ra::Vec3
    material::Material
end
function bounding_box(el::Ellipsoid, time0::Float64, time1::Float64)::AABB
    ma = max(el.ra[1], el.ra[2], el.ra[3])
    return AABB(
        Vec3(-ma, -ma, -ma),
        Vec3(ma, ma, ma),
    )
end
function hit(el::Ellipsoid, r::Ray, t_min::Float64, t_max::Float64)::Option{HitRecord}
    ocn = r.origin ./ el.ra
    rdn = r.direction ./ el.ra
    a = dot(rdn, rdn)
    b = dot(ocn, rdn)
    c = dot(ocn, ocn)
    h = b^2 - a * (c-1)
    if h > 0
        tmp = (-b-sqrt(h))/a
        if t_min < tmp < t_max
            t = tmp
            p = at(r,t)
            n = unit_vector(p ./ Vec3(el.ra[1]^2, el.ra[2]^2, el.ra[3]^2))
            if check_face_normal(r, n)
                ff = true
            else
                ff = false
                n = -n
            end
            return HitRecord(t, p, n, el.material, ff, 0, 0)
        end

        tmp = (-b+sqrt(h))/a
        if t_min < tmp < t_max
            t = tmp
            p = at(r,t)
            n = unit_vector(p ./ Vec3(el.ra[1]^2, el.ra[2]^2, el.ra[3]^2))
            if check_face_normal(r, n)
                ff = true
            else
                ff = false
                n = -n
            end
            return HitRecord(t, p, n, el.material, ff, 0, 0)
        end
    end
    return missing
end
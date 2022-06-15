struct Triangle <: Hittable
    a::Vec3
    b::Vec3
    c::Vec3
    material::Material
end
function bounding_box(tri::Triangle, time0::Float64, time1::Float64)::AABB
    e = .00001
    output_box = AABB(
        Vec3(
            min(tri.a[1], tri.b[1], tri.c[1]) - e,
            min(tri.a[2], tri.b[2], tri.c[2]) - e,
            min(tri.a[3], tri.b[3], tri.c[3]) - e,
        ),
        Vec3(
            max(tri.a[1], tri.b[1], tri.c[1]) + e,
            max(tri.a[2], tri.b[2], tri.c[2]) + e,
            max(tri.a[3], tri.b[3], tri.c[3]) + e,
        )
    )
end
function hit(tri::Triangle, r::Ray, t_min::Float64, t_max::Float64)::Option{HitRecord}
    e = .00001

    edge1 = tri.b - tri.a
    edge2 = tri.c - tri.a
    pvec = cross(r.direction, edge2)
    det = dot(edge1, pvec)

    if abs(det) < e
        return missing
    end

    inv_det = 1.0 / det
    tvec = r.origin - tri.a
    u = dot(tvec, pvec) * inv_det
    if u < 0 || u > 1
        return missing
    end

    qvec = cross(tvec, edge1)
    v = dot(r.direction, qvec) * inv_det
    if v < 0 || u + v > 1
        return missing
    end

    t = dot(edge2, qvec) * inv_det
    if t < e
        return missing
    end

    p = tri.a .* (1-u-v) + tri.b .* u + tri.c .* v
    n = normalize(cross(edge1, edge2))
    if check_face_normal(r, n)
        ff = true
    else
        ff = false
        n = -n
    end

    return HitRecord(t, p, n, tri.material, ff, u, v)
end
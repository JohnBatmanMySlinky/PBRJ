struct Sphere <: Hittable
    center::Vec3
    radius::Float64
    material::Material
end

function hit(s::Sphere, r::Ray, t_min::Float64, t_max::Float64)::Option{HitRecord}
    oc = r.origin .- s.center
    a = dot(r.direction, r.direction)
    b = dot(oc, r.direction)
    c = dot(oc, oc) - s.radius^2
    discriminant = b^2 - a * c
    if discriminant > 0
        tmp = -(b + sqrt(discriminant)) / a
        if t_min < tmp < t_max
            t = tmp
            p = at(r, t)
            n = (p - s.center) / s.radius
            if check_face_normal(r, n)
                ff = true
            else
                ff = false
                n = -n
            end
            uv0 = get_sphere_uv((p-s.center)./s.radius)
            return HitRecord(t, p, n, s.material, ff, uv0[1], uv0[2])
        end
        tmp = (-b + sqrt(discriminant)) / a
        if t_min < tmp < t_max
            t = tmp
            p = at(r, t)
            n = (p - s.center) / s.radius
            if check_face_normal(r, n)
                ff = true
            else
                ff = false
                n = -n
            end
            uv0 = get_sphere_uv((p-s.center)./s.radius)
            return HitRecord(t, p, n, s.material, ff, uv0[1], uv0[2])
        end
    end
    return missing
end

# shared bounding box function
function bounding_box(s::Sphere, time0::Float64, time1::Float64)::AABB
    output_box = AABB(
        s.center .- s.radius,
        s.center .+ s.radius,
    )
    return output_box
end
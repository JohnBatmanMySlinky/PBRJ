struct Cone <: Hittable
    r::Float64
    h::Float64
    phimax::Float64
    material::Material
end
function bounding_box(co::Cone, time0::Float64, time1::Float64)::AABB
    return AABB(
        Vec3(-100, -100, -100),
        Vec3(100, 100, 100)
    )
end
function hit(co::Cone, r::Ray, t_min::Float64, t_max::Float64)::Option{HitRecord}
    k = (co.r / co.h)^2
    a = r.direction[1]^2 + r.direction[2]^2 - k * r.direction[3]^2
    b = 2 * (r.direction[1] * r.origin[1] + r.direction[2] * r.origin[2] - k * r.direction[3] * (r.origin[3] - co.h))
    c = r.origin[1]^2 + r.origin[2]^2 - k * (r.origin[3] - co.h)^2

    discriminant = b^2 - 4 * a * c
    if discriminant > 0
        # getting the right t
        t0 = (-b - sqrt(discriminant)) / 2a
        t1 = (-b + sqrt(discriminant)) / 2a
        
        # neither work
        if t0 > t_max || t1 < t_min
            return missing
        end

        t = t0
        if t < t_min
            t = t1
            if t > t_max
                return missing
            end
        end

        p = at(r, t)
        phi = atan(p[2], p[1])
        if phi < 0
            phi += 2pi
        end

        if p[3] < 0 || p[3] > co.h || phi > co.phimax
            if t == t1
                return missing
            end
            t = t1
            if t > t_max
                return missing
            end
            p = at(r,t)
            phi = atan(p[2], p[1])

            if phi < 0
                phi += 2pi
            end

            if p[3] < 0 || p[3] > co.h || phi > co.phimax
                return missing
            end
        end

        u = phi / co.phimax
        v = p[3] / co.h

        dpdu = Vec3(-co.phimax * p[2], co.phimax * p[1], 0)
        dpdv = Vec3(-p[1] / (1-v), -p[2]/(1-v), co.h)

        n = unit_vector(cross(dpdu, dpdv))
        if check_face_normal(r, n)
            ff = true
        else
            ff = false
            n = -n
        end
        return HitRecord(t, p, n, co.material, ff, u, v)
    end
    return missing
end
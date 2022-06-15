struct Cylinder <: Hittable
    ymin::Float64
    ymax::Float64
    r::Float64
    phimax::Float64
    material::Material
end
function bounding_box(ccyl::Cylinder, time0::Float64, time1::Float64)::AABB
    output_box = AABB(
        Vec3(
            -ccyl.r,
            ccyl.ymin,
            -ccyl.r,
        ),
        Vec3(
            ccyl.r,
            ccyl.ymax,
            ccyl.r,
        )
    )
    return output_box
end
function hit(ccyl::Cylinder, r::Ray, t_min::Float64, t_max::Float64)::Option{HitRecord}
    a = r.direction[1]^2 + r.direction[3]^2
    b = 2(r.direction[1] * r.origin[1] + r.direction[3] * r.origin[3])
    c = r.origin[1]^2 + r.origin[3]^2 - ccyl.r^2

    discriminant = b^2 - 4 * a * c
    if discriminant > 0
        # going with one solution to quadratic
        t = (-b - sqrt(discriminant)) / 2a
        if t_min < t < t_max
            tmp = at(r, t)
            hitrad = sqrt(tmp[1]^2 + tmp[3]^2)
            phit = Vec3(tmp[1] * ccyl.r / hitrad, tmp[2], tmp[3] * ccyl.r / hitrad)

            phi = atan(phit[3], phit[1])
            if phi < 0 
                phi += 2pi
            end
            # if first quadratic dosn't work
            if phit[2] < ccyl.ymin || phit[2] > ccyl.ymax || phi > ccyl.phimax
                # try using second quadratic
                t = (-b + sqrt(discriminant)) / 2a
                tmp = at(r, t)
                hitrad = sqrt(tmp[1]^2 + tmp[3]^2)
                phit = Vec3(tmp[1] * ccyl.r / hitrad, tmp[2], tmp[3] * ccyl.r / hitrad)
    
                phi = atan(phit[3], phit[1])
                if phi < 0 
                    phi += 2pi
                end
                if phit[2] < ccyl.ymin || phit[2] > ccyl.ymax || phi > ccyl.phimax
                    #neither quadratic worked
                    return missing
                end
            end
            
            # proceeding with what ever quadratic worked
            u = phi / ccyl.phimax
            v = (phit[2]-ccyl.ymin)/(ccyl.ymax - ccyl.ymin)

            n = (phit - Vec3(0, phit[2], 0))/ccyl.r
            if check_face_normal(r, n)
                ff = true
            else
                ff = false
                n = -n
            end

            return HitRecord(t, phit, n, ccyl.material, ff, u, v)
        end
    else
        return missing
    end
    return missing
end
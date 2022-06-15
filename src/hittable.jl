struct HitRecord
    t::Float64
    p::Vec3
    normal::Vec3
    material::Material
    front_face::Bool
    u::Float64
    v::Float64
end

function check_face_normal(r::Ray, outward_normal::Vec3)::Bool
    # flip normal sign if false, keep if true
    return dot(r.direction, outward_normal) < 0
end


############################
######## Hittable List #####
############################

struct HittableList <: Hittable
    list::Vector{Hittable}
end

function hit(h::HittableList, r::Ray, tmin::Float64, tmax::Float64)::Option{HitRecord}
    closest = tmax
    rec = missing
    for el in h.list
        temprec = hit(el, r, tmin, closest)
        if !ismissing(temprec)
            rec = temprec
            closest = rec.t
        end
    end
    return rec
end
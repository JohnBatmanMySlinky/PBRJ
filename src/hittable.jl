mutable struct HitRecord
    # world coordinates
    p::Vec3 

    # time of intersection
    t::Float64

    # negative direction of ray
    # angle towards the viewer
    wo::Vec3

    # surface normal in world coorindates
    normal::Vec3
end

mutable struct  













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
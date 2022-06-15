struct Translate <: Hittable
    h::Union{Hittable, BVHNode}
    offset::Vec3
end

function hit(tr::Translate, r::Ray, tmin::Float64, tmax::Float64)::Option{HitRecord}
    moved_r = Ray(r.origin .- tr.offset, r.direction, r.time)
    hit_record = hit(tr.h, moved_r, tmin, tmax)    
    if ismissing(hit_record)
        return missing
    else
        if check_face_normal(moved_r, hit_record.normal)
            ff = true
            n = hit_record.normal
        else
            ff = false
            n = -hit_record.normal
        end
        new_hit_record = HitRecord(
            hit_record.t,
            hit_record.p .+ tr.offset,
            n,
            hit_record.material,
            ff,
            hit_record.u,
            hit_record.v
        )
        return new_hit_record
    end
end

function bounding_box(tr::Translate, time0::Float64, time1::Float64)::Option{AABB}
    tmp = bounding_box(tr.h, time0, time1)
    output_box = AABB(
        tmp.minimum .+ tr.offset,
        tmp.maximum .+ tr.offset
    )
    return output_box
end
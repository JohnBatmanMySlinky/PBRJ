struct FlipFace <: Hittable
    ptr::Hittable
end

function hit(ff::FlipFace, r::Ray, tmin::Float64, tmax::Float64)::Option{HitRecord}
    hit_record = hit(ff.ptr, r, tmin, tmax)
    if !ismissing(hit_record)

        return HitRecord(
            hit_record.t,
            hit_record.p,
            hit_record.normal,
            hit_record.material,
            !hit_record.front_face,
            hit_record.u,
            hit_record.v
        )
    else
        return missing
    end
end

function bounding_box(ff::FlipFace, time0::Float64, time1::Float64)::Option{AABB}
    return bounding_box(ff.ptr, time0, time1)
end
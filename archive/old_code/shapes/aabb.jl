struct AABB
    minimum::Vec3
    maximum::Vec3
end

function hit(b::AABB, r::Ray, tmin::Float64, tmax::Float64)::Bool
    # TODO
    # implement optimized version tho tbd worth it with Julia
    for a = 1:3
        t0 = min(
            (b.minimum[a] - r.origin[a]) / r.direction[a],
            (b.maximum[a] - r.origin[a]) / r.direction[a]
        )
        t1 = max(
            (b.minimum[a] - r.origin[a]) / r.direction[a],
            (b.maximum[a] - r.origin[a]) / r.direction[a]
        )
        tmin = max(t0, tmin)
        tmax = min(t1, tmax)
        if tmax <= tmin
            return false
        end
    end
    return true
end


function surrounding_box(box0::AABB, box1::AABB)::AABB
    small = Vec3(
        min(box0.minimum[1], box1.minimum[1]),
        min(box0.minimum[2], box1.minimum[2]),
        min(box0.minimum[3], box1.minimum[3])
    )
    big = Vec3(
        max(box0.maximum[1], box1.maximum[1]),
        max(box0.maximum[2], box1.maximum[2]),
        max(box0.maximum[3], box1.maximum[3])
    )

    return AABB(small, big)
end
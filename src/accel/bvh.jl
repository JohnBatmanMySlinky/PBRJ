struct BVHNode <: Hittable
    box::AABB
    left::Hittable
    right::Hittable
end

function bounding_box(b::BVHNode, time0::Float64, time1::Float64)::Option{AABB}
    return b.box
end

function hit(b::BVHNode, r::Ray, t_min::Float64, t_max::Float64)::Option{HitRecord}
    if hit(b.box, r, t_min, t_max)
        left_rec = hit(b.left, r, t_min, t_max)
        right_rec = hit(b.right, r, t_min, t_max)

        if !ismissing(left_rec) && !ismissing(right_rec)
            if left_rec.t < right_rec.t
                return left_rec
            else
                return right_rec
            end
        elseif !ismissing(left_rec) && ismissing(right_rec)
            return left_rec
        elseif !ismissing(right_rec) && ismissing(left_rec)
            return right_rec
        else
            return missing
        end
    else
        return missing
    end
end

function construct_bvh(h::HittableList, time0::Float64, time1::Float64)::BVHNode
    # Fuck recursion
    oldh = h.list
    newh = BVHNode[]

    while length(newh) != 1
        newh = BVHNode[]

        # make sure oldh is even
        # TODO make this return null instead of duplicate item
        if length(oldh) % 2 != 0
            push!(oldh, oldh[end])
        end

        # TODO 
        # optimize how this is sorted
        # right now it is sorted
        axis = Int(trunc(rand()*3))+1
        sort!(oldh, by = x -> bounding_box(x, time0, time1).minimum[axis])


        for i = 1:2:length(oldh)
            left = oldh[i]
            right = oldh[i+1]
            node = BVHNode(
                surrounding_box(bounding_box(left, time0, time1), bounding_box(right, time0, time1)),
                left, 
                right
            )
            push!(newh, node)
        end
        oldh = newh
    end
    return newh[1]
end
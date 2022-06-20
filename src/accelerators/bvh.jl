struct BVHNode
    bounds::Bounds3
    left::Union{Primitive, BVHNode}
    right::Union{Primitive, BVHNode}
end

###########################################################
# Bounds of BVHNode just get directed to bounds attribute #
###########################################################

function world_bounds(b::BVHNode)::Bounds3
    return b.bounds
end
function world_bounds(b1::BVHNode, b2::BVHNode)::Bounds3
    return world_bounds(b1.bounds, b2.bounds)
end

############################
##### Construct the BVH ####
############################

function ConstructBVH(primitives::Vector{Primitive})::BVHNode
    old_list = primitives
    new_list = BVHNode[]

    while length(new_list) != 1
        new_list = BVHNode[]

        if length(old_list) % 2 != 0
            push!(old_list, old_list[end])
        end
    
        axis = Int(trunc(rand()*3))+1
        sort!(old_list, by = x -> world_bounds(x).pMin[axis])

        for i = 1:2:length(old_list)
            left = old_list[i]
            right = old_list[i+1]
            node = BVHNode(world_bounds(left, right), left, right)
            push!(new_list, node)
        end
        old_list = new_list
    end
    return new_list[1]
end

#######################################
### Simple intersection with bounds ###
#######################################

function intersect_p(b::Bounds3, r::Ray)::Bool
    tmin = 0
    tmax = r.tMax
    for a = 1:3
        t0 = min(
            (b.pMin[a] - r.origin[a]) / r.direction[a],
            (b.pMax[a] - r.origin[a]) / r.direction[a]
        )
        t1 = max(
            (b.pMin[a] - r.origin[a]) / r.direction[a],
            (b.pMax[a] - r.origin[a]) / r.direction[a]
        )
        tmin = max(t0, tmin)
        tmax = min(t1, tmax)
        if tmax <= tmin
            return false
        end
    end
    return true
end


################################
### Interact with the BVH ######
################################

function Intersect(b::Union{BVHNode, Shape}, r::Ray)
    if intersect_p(b.bounds, r)
        l_check, l_time, l_interaction = Intersect(b.left, r)
        r_check, r_time, r_interaction = Intersect(b.right, r)

        # hits both left & right
        if l_check==true && r_check==true
            if l_time < r_time
                return l_check, l_time, t_interaction
            else
                return r_check, r_time, r_interaction
            end
        # if we hit right, go right
        elseif l_check==false && r_check==true
            return r_check, r_time, r_interaction
        elseif l_check==true && r_check==false
            return l_check, l_time, l_interaction
        else
            return false, nothing, nothing
        end
    else
        return false, nothing, nothing
    end
end
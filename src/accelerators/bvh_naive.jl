struct BVHNodeNaive <: BVHAccel
    bounds::Bounds3
    left::Union{Primitive, BVHNodeNaive}
    right::Union{Primitive, BVHNodeNaive}
end

###########################################################
# Bounds of BVHNodeNaive just get directed to bounds attribute #
###########################################################

function world_bounds(b::BVHNodeNaive)::Bounds3
    return b.bounds
end
function world_bounds(b1::BVHNodeNaive, b2::BVHNodeNaive)::Bounds3
    return world_bounds(b1.bounds, b2.bounds)
end

############################
##### Construct the BVH ####
############################

function ConstructBVHNaive(primitives::Vector{Primitive})::BVHNodeNaive
    old_list = primitives
    new_list = BVHNodeNaive[]

    while length(new_list) != 1
        new_list = BVHNodeNaive[]

        if length(old_list) % 2 != 0
            push!(old_list, old_list[end])
        end
    
        axis = Int(trunc(rand()*3))+1
        sort!(old_list, by = x -> world_bounds(x).pMin[axis])

        for i = 1:2:length(old_list)
            left = old_list[i]
            right = old_list[i+1]
            node = BVHNodeNaive(world_bounds(left, right), left, right)
            push!(new_list, node)
        end
        old_list = new_list
    end
    return new_list[1]
end

################################
### Interact with the BVH ######
################################

function intersect!(b::Union{BVHNodeNaive, Shape}, r::AbstractRay)
    if intersect_p(b.bounds, r)
        l_check, l_time, l_interaction = intersect!(b.left, r)
        r_check, r_time, r_interaction = intersect!(b.right, r)

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

function intersect_p(b::Union{BVHNodeNaive, Shape}, r::AbstractRay)::Bool
    if intersect_p(b.bounds, r)
        l_check = intersect_p(b.left, r)
        r_check = intersect_p(b.right, r)

        # hits both left & right
        if l_check || r_check
            return true
        else
            return false
        end
    else
        return false
    end
end
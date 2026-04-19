# JOHN HACK
# big kludge here so I can build a BVH from spheres
const BVHAble = Union{Primitive, BasicSphere}

#################################################
# The two components of the actual tree of pointers
# 1) Leaf Nodes
# 2) Interior Nodes
#################################################
abstract type LinearBVHNode end
struct LinearBVHLeaf <: LinearBVHNode
    bounds::Bounds3
    primitives_offset::Int64
    n_primitives::Int64
end
struct LinearBVHInterior <: LinearBVHNode
    bounds::Bounds3
    second_child_offset::Int64
    split_axis::Int64
end
const LinearBVH = Union{LinearBVHLeaf, LinearBVHInterior}

###############################################################
#### Additional structs used in construction of tree & array
###############################################################

# pointer to array & bounds & centroid
struct BVHPrimitiveInfo
    primitive_number::Int64
    bounds::Bounds3
    centroid::Pnt3

    function BVHPrimitiveInfo(primitive_number::Int64, bounds::Bounds3)
        # calc centroid
        new(primitive_number, bounds, 0.5 .* bounds.pMin + 0.5 .* bounds.pMax)
    end
end

struct BVHNode
    bounds::Bounds3
    children::Tuple{Maybe{BVHNode}, Maybe{BVHNode}}
    split_axis::Int64
    offset::Int64
    n_primitives::Int64

    # Left node
    function BVHNode(offset::Int64, n_primitives::Int64, bounds::Bounds3)
        return new(bounds, (nothing, nothing), 0, offset, n_primitives)
    end

    # Interior Node
    function BVHNode(axis::Int64, left::BVHNode, right::BVHNode)
        new(world_bounds(left.bounds, right.bounds), (left, right), axis, 0, 0)
    end
end

mutable struct BucketInfo
    count::Int64
    bounds::Bounds3
end

######################################################################################
### Creation of the final data structure
### Insertion point from RayTracing.jl for tree construction
### The final data structure is a Tree with 'pointers' & an array of primitives
### https://aws1.discourse-cdn.com/business5/uploads/julialang/original/2X/a/aa75df26de1d2a062204ae74a7d91dfe7b0c4aa3.png
#######################################################################################
struct BVH <: BVHAccel
    primitives::Vector{<:BVHAble}
    max_node_primitives::Int64
    nodes::Vector{LinearBVH}

    function BVH(primitives::Vector{<:BVHAble}, max_node_primitives::Int64=1)
        max_node_primitives = min(255, max_node_primitives) # why 255?
        length(primitives) == 0 && return new(primitives, max_node_primitives) # doesn't this cause an infinite loop?

        # get primitives info for each primitive
        primitives_info = BVHPrimitiveInfo[
            BVHPrimitiveInfo(i, world_bounds(p)) for (i,p) in enumerate(primitives)
        ]

        # instantiate array component of data structure
        total_nodes = Ref(0)
        ordered_primitives = Vector{BVHAble}(undef, 0)

        # build tree
        root = _build_tree(
            primitives,
            primitives_info,
            1,
            length(primitives),
            total_nodes,
            ordered_primitives,
            max_node_primitives
        )

        # traverse tree
        offset = Ref{UInt64}(1)
        flattened = Vector{LinearBVH}(undef, total_nodes[])
        _traverse(flattened, root, offset)
        @assert total_nodes[] + 1 == offset[]

        new(ordered_primitives, max_node_primitives, flattened)
    end
end

#############################################
### Functions to build and traverse tree
############################################
function _build_tree(
    primitives::Vector{<:BVHAble}, primitives_info::Vector{BVHPrimitiveInfo}, from::Int64, to::Int64,
    total_nodes::Ref{Int64}, ordered_primitives::Vector{<:BVHAble}, max_node_primitives::Int64
)
    total_nodes[] += 1
    n_primitives = to - from + 1
    bounds = mapreduce(
        i -> primitives_info[i].bounds, world_bounds, from:to, init=Bounds3()
    )

    function _create_leaf()::BVHNode
        first_offset = length(ordered_primitives) + 1
        for i in from:to
            push!(ordered_primitives, primitives[primitives_info[i].primitive_number])
        end
        return BVHNode(first_offset, n_primitives, bounds)
    end

    n_primitives == 1 && return _create_leaf()

    centroid_bounds = mapreduce(
        i -> Bounds3(primitives_info[i].centroid), world_bounds, from:to, init=Bounds3()
    )

    dim = maximum_extant(centroid_bounds)

    (!is_valid(centroid_bounds) || centroid_bounds.pMin[dim] == centroid_bounds.pMax[dim]) && return _create_leaf()

    if n_primitives <= 2
        mid = (from + to) ÷ 2
        pmid = mid > from ? mid - from + 1 : 1
        partialsort!(
            @view(primitives_info[from:to]), pmid, by=i -> i.centroid[dim],
        )
    else
        n_buckets = 12
        buckets = BucketInfo[BucketInfo(0,Bounds3(Pnt3(0,0,0))) for _ in 1:n_buckets]

        for i in from:to
            b = Int64(floor(n_buckets * offset(centroid_bounds, primitives_info[i].centroid)[dim])) + 1
            (b == n_buckets + 1) && (b -= 1)
            buckets[b].count += 1
            buckets[b].bounds = world_bounds(buckets[b].bounds,primitives_info[i].bounds)
        end

        costs = Vector{Float64}(undef, n_buckets - 1)
        for i in 1:(n_buckets - 1)
            it1, it2 = 1:i, (i + 1):(n_buckets - 1)
            s1, s2 = 0, 0
            if length(it1) > 0
                s1 = length(it1) * surface_area(
                    mapreduce(b -> buckets[b].bounds, world_bounds, it1),
                )
            end
            if length(it2) > 0
                s2 = length(it2) * surface_area(
                    mapreduce(b -> buckets[b].bounds, world_bounds, it2),
                )
            end
            costs[i] = 1.0 + (s1 + s2) / surface_area(bounds)
        end
        # Find bucket to split that minimizes SAH metric.
        min_cost_id = costs |> argmin
        leaf_cost = n_primitives
        # Either create leaf or split primitives at selected SAH bucket.
        !(
            n_primitives > max_node_primitives
            || costs[min_cost_id] < leaf_cost
        ) && return _create_leaf()
        mid = partition!(primitives_info, from:to, i -> begin
            b = Int64(floor(
                n_buckets * offset(centroid_bounds, i.centroid)[dim]
            )) + 1
            (b == n_buckets + 1) && (b -= 1)
            b <= min_cost_id
        end)
    end
    return BVHNode(
        dim,
        _build_tree(
            primitives, primitives_info, from, mid, total_nodes, ordered_primitives, max_node_primitives,
        ),
        _build_tree(
            primitives, primitives_info, mid + 1, to, total_nodes, ordered_primitives, max_node_primitives,
        ),
    )
end

function _traverse(
    linear_nodes::Vector{LinearBVH}, node::BVHNode, offset::Ref{UInt64},
)
    l_offset = offset[]
    offset[] += 1

    if node.children[1] isa Nothing
        linear_nodes[l_offset] = LinearBVHLeaf(
            node.bounds, node.offset, node.n_primitives,
        )
        return l_offset + 1
    end

    _traverse(linear_nodes, node.children[1], offset)
    second_child_offset = _traverse(linear_nodes, node.children[2], offset) - 1
    linear_nodes[l_offset] = LinearBVHInterior(
        node.bounds, second_child_offset, node.split_axis,
    )
    l_offset + 1
end

#################################################
### Helper functions for intersection
#################################################
function world_bounds(bvh::BVH)::Bounds3
    length(bvh.nodes) > 0 ? bvh.nodes[1].bounds : Bounds3()
end

function world_radius(bvh::BVH)::Float64
    bounds = length(bvh.nodes) > 0 ? bvh.nodes[1].bounds : Bounds3()
    return (maximum(bounds.pMax) - minimum(bounds.pMin))/2
end

#################################################
#### Intersect with BVH
#################################################

function intersect!(bvh::BVH, ray::R, shadow_ray::Bool=false) where {R <: AbstractRay}
    hit = false
    final_time = nothing
    interaction::Maybe{SurfaceInteraction} = nothing
    length(bvh.nodes) == 0 && return hit, nothing, interaction

    ray |> check_direction!
    inv_dir = 1.0 ./ ray.direction
    dir_is_neg = ray.direction |> is_dir_negative

    to_visit_offset, current_node_i = 1, 1
    nodes_to_visit = MVector{128, Int64}(undef)

    while true
        @inbounds ln = bvh.nodes[current_node_i]
        if intersect_p(ln.bounds, ray, inv_dir, dir_is_neg)
            if ln isa LinearBVHLeaf
                if ln.n_primitives > 0
                    @inbounds for i in 0:ln.n_primitives - 1
                        tmp_hit, tmp_time, tmp_interaction = intersect!(
                            bvh.primitives[ln.primitives_offset + i], ray, shadow_ray
                        )
                        if tmp_hit
                            shadow_ray && return true, tmp_time, tmp_interaction
                            hit = true
                            final_time = tmp_time
                            interaction = tmp_interaction
                        end
                    end
                end
                to_visit_offset == 1 && break
                to_visit_offset -= 1
                @inbounds current_node_i = nodes_to_visit[to_visit_offset]
            else
                ln = ln::LinearBVHInterior
                if dir_is_neg[ln.split_axis] == 2
                    @inbounds nodes_to_visit[to_visit_offset] = current_node_i + 1
                    current_node_i = ln.second_child_offset
                else
                    @inbounds nodes_to_visit[to_visit_offset] = ln.second_child_offset
                    current_node_i += 1
                end
                to_visit_offset += 1
            end
        else
            to_visit_offset == 1 && break
            to_visit_offset -= 1
            @inbounds current_node_i = nodes_to_visit[to_visit_offset]
        end
    end
    hit, final_time, interaction
end

function intersect_p(bvh::BVH, ray::R) where {R <: AbstractRay}
    length(bvh.nodes) == 0 && return false

    ray |> check_direction!
    inv_dir = 1.0 ./ ray.direction
    dir_is_neg = ray.direction |> is_dir_negative

    to_visit_offset, current_node_i = 1, 1
    nodes_to_visit = MVector{128, Int64}(undef)

    while true
        @inbounds ln = bvh.nodes[current_node_i]
        if intersect_p(ln.bounds, ray, inv_dir, dir_is_neg)
            if ln isa LinearBVHLeaf
                if ln.n_primitives > 0
                    @inbounds for i in 0:ln.n_primitives - 1
                        intersect_p(
                            bvh.primitives[ln.primitives_offset + i], ray,
                        ) && return true
                    end
                end
                to_visit_offset == 1 && break
                to_visit_offset -= 1
                @inbounds current_node_i = nodes_to_visit[to_visit_offset]
            else
                ln = ln::LinearBVHInterior
                if dir_is_neg[ln.split_axis] == 2
                    @inbounds nodes_to_visit[to_visit_offset] = current_node_i + 1
                    current_node_i = ln.second_child_offset
                else
                    @inbounds nodes_to_visit[to_visit_offset] = ln.second_child_offset
                    current_node_i += 1
                end
                to_visit_offset += 1
            end
        else
            to_visit_offset == 1 && break
            to_visit_offset -= 1
            @inbounds current_node_i = nodes_to_visit[to_visit_offset]
        end
    end
    false
end
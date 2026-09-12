struct ShapeCore
    object_to_world::Transformation
    world_to_object::Transformation
    reverse_orientation::Bool
    transform_swaps_handedness::Bool

    function ShapeCore(
        # TODO
        # if you specify just a translate the inverse is WRONG
        object_to_world=Translate(Pnt3(0,0,0)),
        world_to_object=Inv(Translate(Pnt3(0,0,0))),
        reverse_orientation=false,
        transform_swaps_handedness=false
    )
        return new(
            object_to_world,
            world_to_object,
            reverse_orientation,
            transform_swaps_handedness
        )
    end
end

##############################
##### Bounding of Shapes #####
##############################

# get bounding box of A SINGLE shape
function world_bounds(s::AbstractShape)::Bounds3
    return s.core.object_to_world(ObjectBounds(s))
end
# get bounding box of A SINGLE primitive
function world_bounds(p::Primitive)::Bounds3
    return world_bounds(p.shape)
end

# get surrounding box of TWO shapes
function world_bounds(s1::Primitive, s2::Primitive)::Bounds3
    box1 = world_bounds(s1)
    box2 = world_bounds(s2)

    return world_bounds(box1, box2)
end

#####################################################################
##### Narrow-phase intersection (hit test only, no interaction) ######
#####################################################################
#
# `intersect_geom` answers "does this ray hit this shape, and at what t"
# WITHOUT building a `SurfaceInteraction`. The BVH uses it to find the
# closest primitive; only the winner then pays for a full `intersect`
# (see `finalize_intersection` in primitive.jl and the BVH leaf loop).
#
# This generic fallback just runs the full `intersect` and throws the
# interaction away - correct, but it still allocates. Shapes on the hot
# path (Triangle) override this with a genuinely allocation-free test.
#
# The accept/reject logic of an override MUST match its `intersect`
# exactly: after the BVH picks a winner it re-runs `intersect` on that
# primitive (with `ray.tMax` pinned to the winning t), and a shape that
# said "hit" here but "miss" there would turn into a dropped hit.
function intersect_geom(s::AbstractShape, ray::AbstractRay)::Tuple{Bool, Float64}
    check, t, _ = intersect(s, ray)
    return check, (check ? Float64(t) : Inf)
end

##############################
##### pdf for area light #####
##############################

function pdf(s::AbstractShape, si::Interaction, wi::Vec3)::Float64
    ray = spawn_ray(si, wi)
    check, t, interaction = intersect(s, ray)
    if !check
        return 0.0
    end 
    return distance_squared(si.p, interaction.core.p) / (abs(dot(interaction.core.n, wi) * area(s)))
end

##### pdf for bdpt
function pdf(s::AbstractShape)::Float64
    return 1 / area(s)
end
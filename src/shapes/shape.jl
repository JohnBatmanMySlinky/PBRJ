struct ShapeCore
    object_to_world::Transformation
    world_to_object::Transformation
end

# get bounding box of A SINGLE shape
function world_bounds(s::Shape)::Bounds3
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
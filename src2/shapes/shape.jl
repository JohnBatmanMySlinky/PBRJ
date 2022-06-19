struct ShapeCore
    object_to_world::Transformation
    world_to_object::Transformation
end

# get bounding box of A SINGLE shape
function world_bounds(s::Shape)::Bounds3
    return s.core.object_to_world(ObjectBounds(s))
end
function world_bounds(p::Primitive)::Bounds3
    return world_bounds(p.shape)
end

function world_bounds(b1::Bounds3, b2::Bounds3)::Bounds3
    small = Vec3(
        min(b1.pMin[1], b2.pMin[1]),
        min(b1.pMin[2], b2.pMin[2]),
        min(b1.pMin[3], b2.pMin[3]),
    )

    large = Vec3(
        max(b1.pMax[1], b2.pMax[1]),
        max(b1.pMax[2], b2.pMax[2]),
        max(b1.pMax[3], b2.pMax[3]),
    )

    return Bounds3(
        small,
        large
    )
end

# get surrounding box of TWO shapes
function world_bounds(s1::Primitive, s2::Primitive)::Bounds3
    box1 = world_bounds(s1)
    box2 = world_bounds(s2)

    return world_bounds(box1, box2)
end
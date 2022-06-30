@enum LightFlags::UInt8 begin
    LightDeltaPosition  = 0b1
    LightDeltaDirection = 0b10
    LightArea       = 0b100
    LightInfinite   = 0b1000
end

struct VisibilityTester
    p0::Interaction
    p1::Interaction
end

function unoccluded(vt::VisibilityTester, scene::BVHNode)::Bool
    check, _, _ = Intersect(scene, spawn_ray(vt.p0, vt.p1))
    return !check
end
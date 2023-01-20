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

function unoccluded(vt::VisibilityTester, scene::BVHAccel)::Bool
    check = intersect_p(scene, spawn_shadow_ray(vt.p0, vt.p1))
    return !check
end

function is_delta_light(light::Light)::Bool
    return (light.flags & LightDeltaDirection) || (light.flags & LightDeltaPosition)
end

function is_delta_pos_light(light::Light)::Bool
    return (light.flags & LightDeltaPosition)
end

function is_delta_dir_light(light::Light)::Bool
    return (light.flags & LightDeltaDirection)
end

function is_infinite_light(light::Light)::Bool
    return (light.flags & LightInfinite)
end

function is_area_light(light::Light)::Bool
    return (light.flags & LightArea)
end

function Base.:&(a::LightFlags, b::LightFlags)::Bool
    return (UInt8(a) & UInt8(b)) == UInt8(a)
end
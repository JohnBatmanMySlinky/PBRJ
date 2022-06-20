struct AreaLight
    obj::Hittable
end

function le(al::AreaLight, ray::Ray)::Vec3
    return Vec3(0...)
end
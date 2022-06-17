const Vec3 = SVector{3, Float64}
const Vec2 = SVector{2, Float64}
const Mat4 = SMatrix{4, 4, Float64}

struct Bounds3
    pMin::Vec3
    pMax::Vec3
end
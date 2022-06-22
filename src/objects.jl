# You need all these structures because transformations are not applied consistently!
# PBR 2.8.1 --> Point --> 
# PBR 2.8.2 --> Vector
# PBR 2.8.3 --> Normal

################################
#### Vectors ###################
################################
struct Vec4 <: FieldVector{4, Float64}
    x::Float64
    y::Float64
    z::Float64
    a::Float64
end
struct Vec3 <: FieldVector{3, Float64}
    x::Float64
    y::Float64
    z::Float64
end
struct Vec2 <: FieldVector{2, Float64}
    x::Float64
    y::Float64
end

################################
#### Points ####################
################################
struct Pnt4 <: FieldVector{4, Float64}
    x::Float64
    y::Float64
    z::Float64
    a::Float64
end
struct Pnt3 <: FieldVector{3, Float64}
    x::Float64
    y::Float64
    z::Float64
end
struct Pnt2 <: FieldVector{2, Float64}
    x::Float64
    y::Float64
end

################################
#### Normals ####################
################################
struct Nml3 <: FieldVector{3, Float64}
    x::Float64
    y::Float64
    z::Float64
end

################################
#### Matrices ##################
################################
const Mat4 = SMatrix{4, 4, Float64}

################################
######## Ray ###################
################################
mutable struct Ray
    origin::Pnt3
    direction::Vec3
    time::Float64
    tMax::Float64
end

function at(r::Ray, t::Float64)::Pnt3
    return r.origin .+ t .* r.direction
end

################################
#### AABB ######################
################################
struct Bounds3
    pMin::Pnt3
    pMax::Pnt3
end
struct Bounds2
    pMin::Pnt2
    pMax::Pnt2
end

################################
#### Miscellaneous #############
################################
const Maybe{T} = Union{T, Nothing}
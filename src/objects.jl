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

function inclusive_sides(b::Union{Bounds2, Bounds3})
    return [abs(b1 - (b0 - 1f0)) for (b1, b0) in zip(b.pMax, b.pMin)]
end

################################
######### Spectrum #############
################################
struct Spectrum <: FieldVector{3, Float64}
    r::Float64
    g::Float64
    b::Float64
end
function XYZ_to_RGB(xyz::Pnt3)
    return Spectrum(
        0.412453 * xyz.x + 0.357580 * xyz.y + 0.180423 * xyz.z,
        0.212671 * xyz.x + 0.715160 * xyz.y + 0.072169 * xyz.z,
        0.019334 * xyz.x + 0.119193 * xyz.y + 0.950227 * xyz.z,
    )
end
function RGB_to_XYZ(rgb::Spectrum)
    return Pnt3(
        0.412453 * rgb.r + 0.357580 * rgb.g + 0.180423 * rgb.b,
        0.212671 * rgb.r + 0.715160 * rgb.g + 0.072169 * rgb.b,
        0.019334 * rgb.r + 0.119193 * rgb.g + 0.950227 * rgb.b,
    )
end



################################
#### Miscellaneous #############
################################
const Maybe{T} = Union{T, Nothing}
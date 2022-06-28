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
const Mat3 = SMatrix{3, 3, Float64}

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

function diagonal(b::Union{Bounds2, Bounds3})
    return b.pMax - b.pMin
end

function Base.length(b::Bounds2)::Int64
    delta = ceil.(b.pMax .- b.pMin .+ 1.0)
    return Int64(delta[1] * delta[2])
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

function world_bounds(b1::Bounds2, b2::Bounds2)::Bounds2
    small = Vec2(
        min(b1.pMin[1], b2.pMin[1]),
        min(b1.pMin[2], b2.pMin[2]),
    )

    large = Vec2(
        max(b1.pMax[1], b2.pMax[1]),
        max(b1.pMax[2], b2.pMax[2]),
    )

    return Bounds2(
        small,
        large
    )
end

function intersection(b1::Bounds2, b2::Bounds2)::Bounds2
    return Bounds2(
        max.(b1.pMin, b2.pMin),
        min.(b1.pMax, b2.pMax)
    )
end

function Base.iterate(b::Bounds2, i::Integer = 1,)::Union{Nothing, Tuple{Pnt2, Integer}}
    if i > length(b)
        return nothing
    end

    j = i - 1
    delta = b.pMax .- b.pMin .+ 1.0
    return b.pMin .+ Pnt2(j % delta[1], j / delta[1]), i + 1
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
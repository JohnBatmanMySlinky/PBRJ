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

function Vec3(a::Union{Float64, Int64})::Vec3
    return Vec3(a,a,a)
end

function Vec2(a::Union{Float64, Int64})::Vec2
    return Vec2(a,a)
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

function Pnt3(a::Union{Float64, Int64})::Pnt3
    return Pnt3(a,a,a)
end

function Pnt2(a::Union{Float64, Int64})::Pnt2
    return Pnt2(a,a)
end

# An atomic Pnt3, needed for Film. needed for splat_xyz and bdpt
# PBR 7.9.2
"""
Some light transport algorithms (notable bdpt) require the ability to 'splat' contributions to arbitrary pixels
Rather than compute the final pixel as a weighted average of contributing splats, splats are simply summed. 
"""
mutable struct AtomicPnt3 
    x::Threads.Atomic{Float64}
    y::Threads.Atomic{Float64}
    z::Threads.Atomic{Float64}
end
function AtomicPnt3(p::Pnt3)
    return AtomicPnt3(
        Threads.Atomic{Float64}(p.x),
        Threads.Atomic{Float64}(p.y),
        Threads.Atomic{Float64}(p.z),
    )
end
function AtomicPnt3(x::Float64, y::Float64, z::Float64)
    return AtomicPnt3(
        Threads.Atomic{Float64}(x),
        Threads.Atomic{Float64}(y),
        Threads.Atomic{Float64}(z),
    )
end

# AtomicPnt3 --> Pnt3
function Base.convert(::Type{Pnt3}, a::AtomicPnt3)
    return Pnt3(a.x[], a.y[], a.z[])
end

# atomic add
function Threads.atomic_add!(a::AtomicPnt3, b::Pnt3)
    Threads.atomic_add!(a.x, b.x)
    Threads.atomic_add!(a.y, b.y)
    Threads.atomic_add!(a.z, b.z)
end

################################
#### Normals ####################
################################
struct Nml3 <: FieldVector{3, Float64}
    x::Float64
    y::Float64
    z::Float64
end

function Nml3(a::Union{Float64, Int64})::Nml3
    return Nml3(a,a,a)
end

################################
#### Matrices ##################
################################
const Mat4 = SMatrix{4, 4, Float64}
const Mat3 = SMatrix{3, 3, Float64}
const Mat2 = SMatrix{2, 2, Float64}

################################
######## Ray ###################
################################
mutable struct Ray <: AbstractRay
    origin::Pnt3
    direction::Vec3
    t::Float64
    tMax::Float64
end

function Ray()::Ray
    return Ray(Pnt3(0), Vec3(0), 0.0, typemax(Float64))
end

function at(r::AbstractRay, t::Float64)::Pnt3
    return r.origin .+ t .* r.direction
end

################################
######## Ray Differentials #####
################################
# PBR 2.5.1 
mutable struct RayDifferential <: AbstractRay
    origin::Pnt3
    direction::Vec3
    t::Float64
    tMax::Float64

    has_differentials::Bool
    rx_origin::Pnt3
    ry_origin::Pnt3
    rx_direction::Vec3
    ry_direction::Vec3
end

# instantiate ray differential from Ray
# "There is a constructor to create RayDifferentials from Rays. 
# The constructor sets hasDifferentials to false initially because the neighboring rays, if any, are not known.
function RayDifferential(r::Ray)::RayDifferential
    return RayDifferential(
        r.origin,
        r.direction,
        r.t,
        r.tMax,
        false,
        Pnt3(0),
        Pnt3(0),
        Vec3(0),
        Vec3(0)
    )
end

function scale_differentials!(r::RayDifferential, s::Float64)
    r.rx_origin = r.origin + (r.rx_origin - r.origin) * s
    r.ry_origin = r.origin + (r.ry_origin - r.origin) * s
    r.rx_direction = r.direction + (r.rx_direction - r.direction) * s
    r.ry_direction = r.direction + (r.ry_direction - r.direction) * s
end

function set_direction!(r::AbstractRay, d::Vec3)
    r.direction = Vec3([i ≈ 0.0 ? 0.0 : i for i in d])
end

check_direction!(r::AbstractRay) = set_direction!(r, r.direction)

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

function Bounds2()::Bounds2
    return Bounds2(Pnt2(Inf64), Pnt2(-Inf64))
end
function Bounds3()::Bounds3
    return Bounds3(Pnt3(Inf64), Pnt3(-Inf64))
end

function inside_exclusive(p::Pnt3, b::Bounds3)::Bool
    return (p.x >= b.pMin.x) && (p.x < b.pMax.x) && (p.y >= b.pMin.y) && (p.y < b.pMax.y) && (p.z >= b.pMin.z) && (p.z < b.pMax.z)
end

function inside(p::Pnt3, b::Bounds3)::Bool
    return (p.x >= b.pMin.x) && (p.x <= b.pMax.x) && (p.y >= b.pMin.y) && (p.y <= b.pMax.y) && (p.z >= b.pMin.z) && (p.z <= b.pMax.z)
end

function inside_exclusive(p::Pnt2, b::Bounds2)::Bool
    return (p.x >= b.pMin.x) && (p.x < b.pMax.x) && (p.y >= b.pMin.y) && (p.y < b.pMax.y)
end

function inclusive_sides(b::Bounds3)::Pnt3
    return abs.(b.pMax - b.pMin .+ 1.0)
end

function inclusive_sides(b::Bounds2)::Pnt2
    return abs.(b.pMax - b.pMin .+ 1.0)
end

function diagonal(b::Union{Bounds2, Bounds3})
    return b.pMax - b.pMin
end

function Base.length(b::Bounds2)::Int64
    delta = ceil.(b.pMax .- b.pMin .+ 1.0)
    return Int64(delta[1] * delta[2])
end

function centroid(b::Bounds3)::Pnt3
    return Pnt3(
        (b.pMax.x + b.pMin.x)/2.0,
        (b.pMax.y + b.pMin.y)/2.0,
        (b.pMax.z + b.pMin.z)/2.0
    )
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

function bounding_sphere(b::Bounds3)::Tuple{Pnt3, Float64}
    center = (b.pMax + b.pMin) / 2.0
    radius = inside(center, b) ? norm(center - b.pMax) : 0.0
    return center, radius
end

# should only be using the intersect_p below!!!
# function intersect_p(b::Bounds3, r::AbstractRay)::Bool
#     tmin = 0
#     tmax = r.tMax
#     for i = 1:3
#         x = (b.pMin[i] - r.origin[i]) / r.direction[i]
#         y = (b.pMax[i] - r.origin[i]) / r.direction[i]
#         t0 = min(x,y)
#         t1 = max(x,y)
#         tmin = max(t0, tmin)
#         tmax = min(t1, tmax)
#         if tmax <= tmin
#             return false
#         end
#     end
#     return true
# end

function is_dir_negative(dir::Vec3)
    return Pnt3(
        dir.x < 0 ? 2 : 1,
        dir.y < 0 ? 2 : 1,
        dir.z < 0 ? 2 : 1,
    )
end

#############################################
#####  dir_is_negative: 1 -- false, 2 -- true
#############################################
function intersect_p(b::Bounds3, ray::AbstractRay, inv_dir::Vec3, dir_is_negative::Pnt3)::Bool
    dir_is_negative = Int.(dir_is_negative)
    if dir_is_negative[1] == 2 
        tx_min = (b.pMax[1] - ray.origin.x) * inv_dir[1]
        tx_max = (b.pMin[1] - ray.origin.x) * inv_dir[1]
    else
        tx_min = (b.pMin[1] - ray.origin.x) * inv_dir[1]
        tx_max = (b.pMax[1] - ray.origin.x) * inv_dir[1]
    end

    if dir_is_negative[2] == 2
        ty_min = (b.pMax[2] - ray.origin.y) * inv_dir[2]
        ty_max = (b.pMin[2] - ray.origin.y) * inv_dir[2]
    else
        ty_min = (b.pMin[2] - ray.origin.y) * inv_dir[2]
        ty_max = (b.pMax[2] - ray.origin.y) * inv_dir[2]
    end

    (tx_min > ty_max || ty_min > tx_max) && return false
    ty_min > tx_min && (tx_min = ty_min;)
    ty_max > tx_max && (tx_max = ty_max;)

    if dir_is_negative[3] == 2
        tz_min = (b.pMax[3] - ray.origin.z) * inv_dir[3]
        tz_max = (b.pMin[3] - ray.origin.z) * inv_dir[3]
    else
        tz_min = (b.pMin[3] - ray.origin.z) * inv_dir[3]
        tz_max = (b.pMax[3] - ray.origin.z) * inv_dir[3]
    end
    (tx_min > tz_max || tz_min > tx_max) && return false

    (tz_min > tx_min) && (tx_min = tz_min;)
    (tz_max < tx_max) && (tx_max = tz_max;)
    tx_min < ray.tMax && tx_max > 0
end

function Base.iterate(b::Bounds2, i::Integer = 1,)::Union{Nothing, Tuple{Pnt2, Integer}}
    if i > length(b)
        return nothing
    end

    j = i - 1
    delta = b.pMax .- b.pMin .+ 1.0
    return b.pMin .+ Pnt2(j % delta[1], j ÷ delta[1]), i + 1
end

function Bounds3(p::Pnt3)
    return Bounds3(p, p)
end

function maximum_extant(b::Bounds3)
    d = diagonal(b)
    if d.x > d.y && d.x > d.z
        return 1
    elseif d.y > d.z
        return 2
    end
    return 3
end

function is_valid(b::Bounds3)::Bool
    all(b.pMin .!= Inf64) && all(b.pMax .!= -Inf64)
end

function offset(b::Bounds3, p::Pnt3)
    o = p - b.pMin
    g = b.pMax .> b.pMin
    !any(g) && return o
    return Pnt3(
        o[1] / (g[1] ? b.pMax[1] - b.pMin[1] : 1.0),
        o[2] / (g[2] ? b.pMax[2] - b.pMin[2] : 1.0),
        o[3] / (g[3] ? b.pMax[3] - b.pMin[3] : 1.0),
    )
end

function surface_area(b::Bounds3)
    d = diagonal(b)
    return 2 * (d.x * d.y + d.x * d.z + d.y * d.z)
end

# Index through 8 corners.
function corner(b::Bounds3, c::Integer)
    c -= 1
    Pnt3(
        b[(c & 1) + 1][1],
        b[(c & 2) != 0 ? 2 : 1][2],
        b[(c & 4) != 0 ? 2 : 1][3],
    )
end

# make bounds index-able
function Base.getindex(b::Union{Bounds2, Bounds3}, i::Integer)
    i == 1 && return b.pMin
    i == 2 && return b.pMax
    error("Invalid index `$i`. Only `1` & `2` are valid.")
end

################################
######### Spectrum #############
################################
struct Spectrum <: FieldVector{3, Float64}
    r::Float64
    g::Float64
    b::Float64
end

function Spectrum(a::Union{Float64,Int64})::Spectrum
    return Spectrum(a,a,a)
end

function Spectrum(a::ColorTypes.RGBA{Float16})::Spectrum
    return Spectrum(a.r, a.g, a.b)
end

function is_black(s::Spectrum)::Bool
    return all(s .== 0.0)
end

function XYZ_to_RGB(xyz::Pnt3)::Spectrum
    # return Spectrum(
    #     0.412453 * xyz.x + 0.357580 * xyz.y + 0.180423 * xyz.z,
    #     0.212671 * xyz.x + 0.715160 * xyz.y + 0.072169 * xyz.z,
    #     0.019334 * xyz.x + 0.119193 * xyz.y + 0.950227 * xyz.z,
    # )
    return xyz
end
function RGB_to_XYZ(rgb::Spectrum)::Pnt3
    # return Pnt3(
    #     0.412453 * rgb.r + 0.357580 * rgb.g + 0.180423 * rgb.b,
    #     0.212671 * rgb.r + 0.715160 * rgb.g + 0.072169 * rgb.b,
    #     0.019334 * rgb.r + 0.119193 * rgb.g + 0.950227 * rgb.b,
    # )
    return rgb
end

# TODO I don't think I should need this??
function Base.:*(a::Spectrum, b::Spectrum)
    return Spectrum(a.r*b.r, a.g*b.g, a.b*b.b)
end

# AtomicPnt3 --> Spectrum
function Base.convert(::Type{Spectrum}, a::AtomicPnt3)
    return Spectrum(a.x[], a.y[], a.z[])
end

################################
#### Miscellaneous #############
################################
const Maybe{T} = Union{T, Nothing}
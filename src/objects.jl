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

################################
#### RGB ######################
################################
struct RGBPBRT <: FieldVector{3, Float64}
    r::Float64
    g::Float64
    b::Float64
end

################################
#### XYZ ######################
################################
struct XYZPBRT <: FieldVector{3, Float64}
    x::Float64
    y::Float64
    z::Float64
end

# An atomic XYZ, needed for Film. needed for splat_xyz and bdpt
# PBR 7.9.2
"""
Some light transport algorithms (notable bdpt) require the ability to 'splat' contributions to arbitrary pixels
Rather than compute the final pixel as a weighted average of contributing splats, splats are simply summed. 
"""
mutable struct AtomicXYZPBRT
    x::Threads.Atomic{Float64}
    y::Threads.Atomic{Float64}
    z::Threads.Atomic{Float64}
end
function AtomicXYZPBRT(p::XYZPBRT)
    return AtomicXYZPBRT(
        Threads.Atomic{Float64}(p.x),
        Threads.Atomic{Float64}(p.y),
        Threads.Atomic{Float64}(p.z),
    )
end
function AtomicXYZPBRT(x::Float64, y::Float64, z::Float64)
    return AtomicXYZPBRT(
        Threads.Atomic{Float64}(x),
        Threads.Atomic{Float64}(y),
        Threads.Atomic{Float64}(z),
    )
end

# AtomicXYZPBRT --> XYZPBRT
function Base.convert(::Type{XYZPBRT}, a::AtomicXYZPBRT)
    return XYZPBRT(a.x[], a.y[], a.z[])
end

# atomic add
function Threads.atomic_add!(a::AtomicXYZPBRT, b::XYZPBRT)
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
const Mat4 = SMatrix{4, 4, Float64, 16}
const Mat3 = SMatrix{3, 3, Float64, 9}
const Mat2 = SMatrix{2, 2, Float64, 4}

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
    return Int64(delta.x * delta.y)
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

function expand(b::Bounds3, delta::Float64)::Bounds3
    return Bounds3(
        b.pMin - Pnt3(delta, delta, delta),
        b.pMax + Pnt3(delta, delta, delta),
    )
end

function overlaps(b1::Bounds3, b2::Bounds3)::Bool
    x = (b1.pMax.x >= b2.pMin.x) && (b1.pMin.x <= b2.pMax.x)
    y = (b1.pMax.y >= b2.pMin.y) && (b1.pMin.y <= b2.pMax.y)
    z = (b1.pMax.z >= b2.pMin.z) && (b1.pMin.z <= b2.pMax.z)
    return x && y && z
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

function intersect_p(b::Bounds3, ray::AbstractRay)::Tuple{Bool, Float64, Float64}
    t0 = 0.0
    t1 = ray.tMax
    for i in 1:3
        # update interval for _i_th bounding box slab
        inv_ray_dir = 1.0 / ray.direction[i]
        t_near = (b.pMin[i] - ray.origin[i]) * inv_ray_dir
        t_far = (b.pMax[i] - ray.origin[i]) * inv_ray_dir

        # update parametric interval from slab intersection $t$ values
        if t_near > t_far
            t_far, t_near = t_near, t_far
        end

        # update _t_far_ to ensure robust ray--bounds intersection
        t_far *= 1.0 + 2.0 * gamma(3)
        t0 = t_near > t0 ? t_near : t0
        t1 = t_far < t1 ? t_far : t1
        if t0 > t1
            return false, 0.0, 0.0
        end
    end
    return true, t0, t1
end

function intersect_p(b::Bounds3, ray::AbstractRay, ray_t_max::Float64)::Tuple{Bool, Float64, Float64}
    t0 = 0.0
    t1 = ray_t_max
    for i in 1:3
        # update interval for _i_th bounding box slab
        inv_ray_dir = 1.0 / ray.direction[i]
        t_near = (b.pMin[i] - ray.origin[i]) * inv_ray_dir
        t_far = (b.pMax[i] - ray.origin[i]) * inv_ray_dir

        # update parametric interval from slab intersection $t$ values
        if t_near > t_far
            t_far, t_near = t_near, t_far
        end

        # update _t_far_ to ensure robust ray--bounds intersection
        t_far *= 1.0 + 2.0 * gamma(3)
        t0 = t_near > t0 ? t_near : t0
        t1 = t_far < t1 ? t_far : t1
        if t0 > t1
            return false, 0.0, 0.0
        end
    end
    return true, t0, t1
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
#### Miscellaneous #############
################################
const Maybe{T} = Union{T, Nothing}
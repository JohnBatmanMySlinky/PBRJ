################################
######## Ray ###################
################################
# tMax is the one field that's genuinely mutable over a ray's lifetime - it's
# the shrinking "closest hit so far" bound threaded through BVH traversal
# (mirrors PBRT's C++ Ray, which likewise declares `mutable Float tMax` on an
# otherwise-fixed ray). It's a Base.RefValue so that bound can still be
# updated in place while everything else about a Ray is truly immutable.
struct Ray <: AbstractRay
    origin::Pnt3
    direction::Vec3
    t::Float64
    tMax::Base.RefValue{Float64}
    medium::Maybe{Handle{:Medium}}
end

function Ray(o::Pnt3, d::Vec3, t::Float64, tmax::Float64, medium::Maybe{Handle{:Medium}})
    return Ray(o, d, t, Ref(tmax), medium)
end

function Ray(o::Pnt3, d::Vec3, t::Float64, tmax::Float64)
    return Ray(o, d, t, tmax, nothing)
end

function Ray()::Ray
    return Ray(Pnt3(0.0), Vec3(0), 0.0, typemax(Float64))
end

function at(r::AbstractRay, t::Float64)::Pnt3
    return r.origin .+ t .* r.direction
end

################################
######## Ray Differentials #####
################################
# PBR 2.5.1
struct RayDifferential <: AbstractRay
    origin::Pnt3
    direction::Vec3
    t::Float64
    tMax::Base.RefValue{Float64}

    has_differentials::Bool
    rx_origin::Pnt3
    ry_origin::Pnt3
    rx_direction::Vec3
    ry_direction::Vec3

    medium::Maybe{Handle{:Medium}}
end

function RayDifferential(origin::Pnt3, direction::Vec3, t::Float64, tMax::Float64, hasd::Bool,
    rxo::Pnt3, ryo::Pnt3, rxd::Vec3, ryd::Vec3, medium::Maybe{Handle{:Medium}}
)
    return RayDifferential(origin, direction, t, Ref(tMax), hasd, rxo, ryo, rxd, ryd, medium)
end

function RayDifferential(origin::Pnt3, direction::Vec3, t::Float64, tMax::Float64, hasd::Bool,
    rxo::Pnt3, ryo::Pnt3, rxd::Vec3, ryd::Vec3
)
    return RayDifferential(origin, direction, t, tMax, hasd, rxo, ryo, rxd, ryd, nothing)
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
        Pnt3(0.0),
        Pnt3(0.0),
        Vec3(0),
        Vec3(0),
        r.medium
    )
end

function scale_differentials(r::RayDifferential, s::Float64)::RayDifferential
    rx_origin = r.origin + (r.rx_origin - r.origin) * s
    ry_origin = r.origin + (r.ry_origin - r.origin) * s
    rx_direction = r.direction + (r.rx_direction - r.direction) * s
    ry_direction = r.direction + (r.ry_direction - r.direction) * s
    return RayDifferential(r.origin, r.direction, r.t, r.tMax, r.has_differentials, rx_origin, ry_origin, rx_direction, ry_direction, r.medium)
end

# Non-mutating "with a different direction" (e.g. re-normalizing, or fixing up
# -0.0 components before a BVH slab test) - preserves tMax's identity (the
# shared Ref), so any in-flight closest-hit tracking on `r` still applies.
function set_direction(r::Ray, d::Vec3)::Ray
    return Ray(r.origin, d, r.t, r.tMax, r.medium)
end

function set_direction(r::RayDifferential, d::Vec3)::RayDifferential
    return RayDifferential(r.origin, d, r.t, r.tMax, r.has_differentials, r.rx_origin, r.ry_origin, r.rx_direction, r.ry_direction, r.medium)
end

function check_direction(r::AbstractRay)
    d = r.direction
    return set_direction(r, Vec3(
        d.x ≈ 0.0 ? 0.0 : d.x,
        d.y ≈ 0.0 ? 0.0 : d.y,
        d.z ≈ 0.0 ? 0.0 : d.z,
    ))
end

# Non-mutating "with a different origin" - used when re-tracing a ray from a
# new starting point while keeping its direction/medium/tMax bound.
function with_origin(r::Ray, o::Pnt3)::Ray
    return Ray(o, r.direction, r.t, r.tMax, r.medium)
end

function with_origin(r::RayDifferential, o::Pnt3)::RayDifferential
    return RayDifferential(o, r.direction, r.t, r.tMax, r.has_differentials, r.rx_origin, r.ry_origin, r.rx_direction, r.ry_direction, r.medium)
end

# Non-mutating "restart from a new origin/t/tMax" - a genuinely fresh tMax
# bound (own Ref), used when re-running a traversal from scratch.
function with_origin_t_tmax(r::Ray, o::Pnt3, t::Float64, tmax::Float64)::Ray
    return Ray(o, r.direction, t, tmax, r.medium)
end

function with_origin_t_tmax(r::RayDifferential, o::Pnt3, t::Float64, tmax::Float64)::RayDifferential
    return RayDifferential(o, r.direction, t, tmax, r.has_differentials, r.rx_origin, r.ry_origin, r.rx_direction, r.ry_direction, r.medium)
end

Base.show(io::IO, r::Ray) = print(io, "o=$(r.origin), d=$(r.direction), t=$(r.t), tMax=$(r.tMax[]), hasMedium=$(!(r.medium isa Nothing))")
Base.show(io::IO, r::RayDifferential) = print(io, "o=$(r.origin), d=$(r.direction), t=$(r.t), tMax=$(r.tMax[]), hasMedium=$(!(r.medium isa Nothing)), xo=$(r.rx_origin), xd=$(r.rx_direction), yo=$(r.ry_origin), yd=$(r.ry_direction)")

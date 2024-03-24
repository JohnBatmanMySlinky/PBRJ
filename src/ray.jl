################################
######## Ray ###################
################################
mutable struct Ray <: AbstractRay
    origin::Pnt3
    direction::Vec3
    t::Float64
    tMax::Float64
    medium::Maybe{AbstractMedium}
end

function Ray(o::Pnt3, d::Vec3, t::Float64, tmax::Float64)
    return Ray(o, d, t, tmax, nothing)
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

    medium::Maybe{AbstractMedium}
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
        Pnt3(0),
        Pnt3(0),
        Vec3(0),
        Vec3(0),
        r.medium
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

Base.show(io::IO, r::AbstractRay) = print(io, "$(r.origin), $(r.direction), $(r.t), $(r.tMax), $(!(r.medium isa Nothing))")
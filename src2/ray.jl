struct Ray
    origin::Vec3
    direction::Vec3
    time::Float64
    tMax::Float64
end

function at(r::Ray, t::Float64)::Vec3
    return r.origin .+ t .* r.direction
end
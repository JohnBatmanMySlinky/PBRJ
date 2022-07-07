function solve_quadratic(a::Float64, b::Float64, c::Float64)::Tuple{Bool, Float64, Float64}
    # Find disriminant.
    d = b ^ 2 - 4 * a * c
    if d < 0
        return false, NaN32, NaN32
    end
    d = d |> sqrt
    # Compute roots.
    q = -0.5f0 * (b + (b < 0 ? -d : d))
    t0 = q / a
    t1 = c / q
    if t0 > t1
        t0, t1 = t1, t0
    end
    return true, t0, t1
end

function distance(p1::Pnt3, p2::Pnt3)::Float64
    return norm(p1 - p2)
end

function distance_squared(p1::Pnt3, p2::Pnt3)::Float64
    p = p1 - p2
    return dot(p,p)
end

function lerp(t::Float64, a::Float64, b::Float64)::Float64
    return a + t * (b - a)
end

function spherical_phi(v::Vec3)
    p = atan(v.y, v.x)
    return p < 0 ? (p + 2 * pi) : p
end

function spherical_theta(v::Vec3)
    return acos(clamp(v.z, -1, 1))
end
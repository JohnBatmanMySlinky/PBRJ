function solve_quadratic(a::Float32, b::Float32, c::Float32)::Tuple{Bool, Float32, Float32}
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
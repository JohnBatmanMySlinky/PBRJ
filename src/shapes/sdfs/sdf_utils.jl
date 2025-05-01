function sdf_smooth_union(d1::Float64, d2::Float64, k::Float64)::Float64
    h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0)
    return min(d2, d1, h) - k * h * (1.0 - h)
end
function sdf_smooth_subtraction(d1::Float64, d2::Float64, k::Float64)::Float64
    h = clamp(0.5 - 0.5 * (d2 + d1) / k, 0.0, 1.0)
    return min(d2, -d1, h) + k * h * (1.0 - h)
end
function sdf_smooth_intersection(d1::Float64, d2::Float64, k::Float64)::Float64
    h = clamp(0.5 - 0.5 * (d2 - d1)/k, 0.0, 1.0)
    return min(d2, d1, h) + k * h * (1.0 - h)
end
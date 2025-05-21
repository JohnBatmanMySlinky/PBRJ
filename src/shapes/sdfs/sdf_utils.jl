struct SDFSmoothUnion <: SDFFunction
    k::Float64
end

function (sdff::SDFSmoothUnion)(d1::Float64, d2::Float64)::Float64
    h = clamp(0.5 + 0.5 * (d2 - d1) / sdff.k, 0.0, 1.0)
    return min(d2, d1, h) - sdff.k * h * (1.0 - h)
end

# function sdf_union(d1::Float64, d2::Float64, ::Float64)::Float64
#     return min(d1, d2)
# end

# function sdf_smooth_subtraction(d1::Float64, d2::Float64, k::Float64)::Float64
#     h = clamp(0.5 - 0.5 * (d2 + d1) / k, 0.0, 1.0)
#     return min(d2, -d1, h) + k * h * (1.0 - h)
# end
# function sdf_subtraction(d1::Float64, d2::Float64, ::Float64)::Float64
#     return max(-d1, d2)
# end

# function sdf_smooth_intersection(d1::Float64, d2::Float64, k::Float64)::Float64
#     h = clamp(0.5 - 0.5 * (d2 - d1)/k, 0.0, 1.0)
#     return min(d2, d1, h) + k * h * (1.0 - h)
# end
# function sdf_intersection(d1::Float64, d2::Float64, ::Float64)::Float64
#     return max(d1, d2)
# end

# function sdf_xor(d1::Float64, d2::Float64, ::Float64)::Float64
#     return max(min(d1,d2), -max(d1,d2))
# end
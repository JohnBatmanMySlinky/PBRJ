include("../src/RayTracing.jl")

"""
64 bits * 500px * 500 px * 10dim * 10 dim * 5dim * 3 (channels of 1D and 2D) ~ 3gb so 2.78 gb is low???
"""
function run(N::Int64, D::Int64)::Bool
    for n in 1:N
        ss = ss = RayTracing.StratifiedSampler(D, D, 5, true)
    end
    return true
end
@time run(500*500, 10)


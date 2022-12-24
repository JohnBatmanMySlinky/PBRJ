# EXECUTE WITH julia -i test_samplers.jl

using Plots
pyplot()
include("../src/RayTracing.jl")


function do_US(n::Int64)::Tuple{Vector{Float64}, Vector{Float64}}
    X = Float64[]
    Y = Float64[]
    US = RayTracing.UniformSampler(n)
    RayTracing.start_pixel!(US, RayTracing.Pnt2(0,0))
    while RayTracing.has_next_sample(US)
        x, y = RayTracing.get_2D!(US)
        push!(X,x)
        push!(Y,y)
        RayTracing.start_next_sample!(US)
    end
    return X, Y
end

function do_SS(n::Int64, jitter::Bool)::Tuple{Vector{Float64}, Vector{Float64}}
    X = Float64[]
    Y = Float64[]
    SS = RayTracing.StratifiedSampler(
        Int(trunc(n^.5)),
        Int(trunc(n^.5)),
        1,
        jitter
    )
    RayTracing.start_pixel!(SS, RayTracing.Pnt2(0,0))
    while RayTracing.has_next_sample(SS)
        x, y = RayTracing.get_2D!(SS)
        push!(X,x)
        push!(Y,y)
        RayTracing.start_next_sample!(SS)
    end
    return X, Y
end

function do_HS(n::Int64)::Tuple{Vector{Float64}, Vector{Float64}}
    X = Float64[]
    Y = Float64[]
    HS = RayTracing.HaltonSampler(
        n,
        RayTracing.Bounds2(RayTracing.Pnt2(0,0), RayTracing.Pnt2(10,1))
    )
    RayTracing.start_pixel!(HS, RayTracing.Pnt2(0,0))
    while RayTracing.has_next_sample(HS)
        x, y = RayTracing.get_2D!(HS)
        push!(X,x)
        push!(Y,y)
        RayTracing.start_next_sample!(HS)
    end
    return X, Y
end

# US_x, US_y = do_US(1024)
# US_plot = plot(US_x, US_y, seriestype=:scatter, label="Uniform Sampler")
# gui(US_plot)

# SS_x, SS_y = do_SS(1024, false)
# SS_plot = plot(SS_x, SS_y, seriestype=:scatter, label="Stratified Sampler - no jitter", reuse=false)
# gui(SS_plot)

# SS_x, SS_y = do_SS(1024, true)
# SS_plot = plot(SS_x, SS_y, seriestype=:scatter, label="Stratified Sampler - yes jitter", reuse=false)
# gui(SS_plot)

HS_x, HS_y = do_HS(1024)
HS_plot = plot(HS_x, HS_y, seriestype=:scatter, label="Halton Sampler", reuse=false)
gui(HS_plot)
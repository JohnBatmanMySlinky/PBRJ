# EXECUTE WITH julia -i test_samplers.jl

using Plots
using Random
pyplot()
include("../src/RayTracing.jl")

#######################################
######## VISUALIZE SAMPLERS ##########
#######################################

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
    # shuffle the indices because SS goes stratification by stratification
    idx=shuffle(1:length(X))
    return X[idx], Y[idx]
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


function estimate_area_of_a_circle(n_samples::Int64)
    US_x, US_y = do_US(n_samples)
    SS_x, SS_y = do_SS(n_samples, true)
    HS_x, HS_y = do_HS(n_samples)

    US_in = 0
    SS_in = 0
    HS_in = 0
    US_π = Vector{Float64}(undef, n_samples)
    SS_π = Vector{Float64}(undef, n_samples)
    HS_π = Vector{Float64}(undef, n_samples)
    for n in 1:n_samples
        if (US_x[n]-.5)^2 + (US_y[n]-.5)^2 <= .5^2
            US_in += 1
        end
        if (SS_x[n]-.5)^2 + (SS_y[n]-.5)^2 <= .5^2
            SS_in += 1
        end
        if (HS_x[n]-.5)^2 + (HS_y[n]-.5)^2 <= .5^2
            HS_in += 1
        end
        US_π[n] = US_in * 4 / n
        SS_π[n] = SS_in * 4 / n
        HS_π[n] = HS_in * 4 / n
    end
    
    π_plot = plot(1:n_samples, [US_π, SS_π, HS_π])
    gui(π_plot)
end

function PLOT(N::Int64)
    US_x, US_y = do_US(N)
    US_plot = plot(US_x, US_y, seriestype=:scatter, label="Uniform Sampler: " * string(N) * " samples")
    gui(US_plot)

    SS_x, SS_y = do_SS(N, false)
    SS_plot = plot(SS_x, SS_y, seriestype=:scatter, label="Stratified Sampler: no jitter: " * string(N) * " samples", reuse=false)
    gui(SS_plot)

    SS_x, SS_y = do_SS(N, true)
    SS_plot = plot(SS_x, SS_y, seriestype=:scatter, label="Stratified Sampler: yes jitter: " * string(N) * " samples", reuse=false)
    gui(SS_plot)

    HS_x, HS_y = do_HS(N)
    HS_plot = plot(HS_x, HS_y, seriestype=:scatter, label="Halton Sampler: " * string(N) * " samples", reuse=false)
    gui(HS_plot)
end



PLOT(256)
estimate_area_of_a_circle(256)
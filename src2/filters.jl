struct LanczosSincFilter <: Filter
    radius::Vec2
    tau::Float64
end

function (f::LanczosSincFilter)(p::Point2f0)::Float64
    return windowed_sinc(p[1], f.radius[1], f.tau) * windowed_sinc(p[2], f.radius[2], f.tau)
end

function sinc(x::Float64)::Float64
    x = abs(x)
    if x < 1e-5
        return 1
    end
    x *= π
    return sin(x) / x
end

function windowed_sinc(x::Float64, r::Float64, tau::Float64)::Float64
    x = abs(abs)
    if x > r
        return 0
    end
    return sinc(x) * sinc(x / tau)
end
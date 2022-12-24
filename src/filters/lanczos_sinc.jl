struct LanczosSincFilter <: Filter
    radius::Pnt2
    tau::Float64

    function LanczosSincFilter()
        return new(Pnt2(4,4), 3.0)
    end
end

function (f::LanczosSincFilter)(p::Pnt2)::Float64
    return windowed_sinc(p.x, f.radius.x, f.tau) * windowed_sinc(p.y, f.radius.y, f.tau)
end

function sinc(x::Float64)::Float64
    x = abs(x)
    x < 1e-5 && return 1.0
    return sin(pi * x) / (pi * x)
end

function windowed_sinc(x::Float64, r::Float64, tau::Float64)::Float64
    x = abs(x)
    x > r && return 0.0
    return sinc(x) * sinc(x / tau)
end
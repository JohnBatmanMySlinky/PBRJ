struct GaussianFilter <: Filter
    radius::Pnt2
    alpha::Float64
    exp_x::Float64
    exp_y::Float64

    function GaussianFilter(radius::Pnt2, alpha::Float64=2.0)
        return new(
            radius,
            alpha,
            exp(-alpha * radius.x^2),
            exp(-alpha * radius.y^2)
        )
    end
end

function (g::GaussianFilter)(p::Pnt2)::Float64
    return gaussian(g, p.x, g.exp_x) * gaussian(g, p.y, g.exp_y)
end

function gaussian(g::GaussianFilter, d::Float64, expv::Float64)::Float64
    return max(0.0, exp(-g.alpha * d^2)-expv)
end
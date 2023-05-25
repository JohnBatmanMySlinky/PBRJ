struct MitchellFilter <: Filter
    radius::Pnt2
    B::Float64
    C::Float64
    "it is recommended that B+2C=1"
end

function (m::MitchellFilter)(p::Pnt2)::Float64
    return mitchell1D(m, p.x / m.radius.x) * mitchell1D(m, p.y / m.radius.y)
end

function mithcell1d(m::MitchellFilter, x::Float64)::Float64
    x = abs(2.0 * x)
    if x > 1.0
        return ((-m.B - 6.0 * m.C) * x^3 + (6.0 * m.B + 30.0 * m.C) * x^2 + (-12.0 * m.B - 48.0 * m.C) * x + (8.0 * m.b + 24.0 * m.C)) / 6.0
    else
        return ((12.0 - 9.0 * m.B - 6.0 * m.C) * x^3 + (-18.0 + 12.0 * m.B + 6.0 * m.C) * x^2 + (6.0 - 2.0 *m.B)) * (1.0 / 6.0)
    end
end
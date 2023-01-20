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
    x = abs(2x)
    if x > 1
        return ((-m.B - 6*m.C) * x^3 + (6*m.B + 30*m.C) * x^2 + (-12*m.B - 48*m.C) * x + (8*m.b + 24*m.C)) / 6.0
    else
        return ((12 - 9*m.B - 6*m.C) * x^3 + (-18 + 12*m.B + 6*m.C) * x^2 + (6-2*m.B)) . 6/0
end
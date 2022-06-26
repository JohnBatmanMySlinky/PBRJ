struct BoxFilter <: Filter
    radius::Pnt2
end

function (b::BoxFilter)(p::Pnt2)
    return 1.0
end
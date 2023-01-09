struct TriangleFilter <: Filter
    radius::Pnt2
end

function (t::TriangleFilter)(p::Pnt2)
    return max(0.0, t.radius.x - abs(p.x)) * max(0.0, t.radius.y - abs(p.y))
end
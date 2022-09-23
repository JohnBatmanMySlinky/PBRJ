# TODO variable materials per rectangle
function Box(t::Transformation, p_min::Pnt3, p_max::Pnt3, material::Material)::Vector{Primitive}
    if any(p_min .>= p_max)
        error("bound erorr in ya box")
    end

    stuff = Primitive[]

    # XYs
    push!(stuff, Primitive(XYRectangle(t, Pnt2(p_min.x, p_max.x), Pnt2(p_min.y, p_max.y), p_max.z, false, false), material, nothing))
    push!(stuff, Primitive(XYRectangle(t, Pnt2(p_min.x, p_max.x), Pnt2(p_min.y, p_max.y), p_min.z, false, false), material, nothing))

    # XZs
    push!(stuff, Primitive(XZRectangle(t, Pnt2(p_min.x, p_max.x), Pnt2(p_min.z, p_max.z), p_max.y, false, false), material, nothing))
    push!(stuff, Primitive(XZRectangle(t, Pnt2(p_min.x, p_max.x), Pnt2(p_min.z, p_max.z), p_min.y, false, false), material, nothing))

    # YZs
    push!(stuff, Primitive(YZRectangle(t, Pnt2(p_min.y, p_max.y), Pnt2(p_min.z, p_max.z), p_max.x, false, false), material, nothing))
    push!(stuff, Primitive(YZRectangle(t, Pnt2(p_min.y, p_max.y), Pnt2(p_min.z, p_max.z), p_min.x, false, false), material, nothing))

    return stuff
end 

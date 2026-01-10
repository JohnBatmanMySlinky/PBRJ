# TODO variable materials per rectangle
# TODO allow alpha mask
function Box(sc::ShapeCore, p_min::Pnt3, p_max::Pnt3, material::UInt32)::Vector{Primitive}
    if any(p_min .>= p_max)
        error("bound erorr in ya box")
    end

    stuff = Primitive[]

    # XYs
    xy1s = Rectangle(Pnt2(p_min.x, p_min.y), Pnt2(p_max.x, p_max.y), p_max.z, 3, sc, false, nothing)
    for xy1 in xy1s
        push!(stuff, Primitive(xy1, material, nothing))
    end
    xy2s = Rectangle(Pnt2(p_min.x, p_min.y), Pnt2(p_max.x, p_max.y), p_min.z, 3, sc, false, nothing)
    for xy2 in xy2s
        push!(stuff, Primitive(xy2, material, nothing))
    end

    # XZs
    xz1s = Rectangle(Pnt2(p_min.x, p_min.z), Pnt2(p_max.x, p_max.z), p_max.y, 2, sc, false, nothing)
    for xz1 in xz1s
        push!(stuff, Primitive(xz1, material, nothing))
    end
    xz2s = Rectangle(Pnt2(p_min.x, p_min.z), Pnt2(p_max.x, p_max.z), p_min.y, 2, sc, false, nothing)
    for xz2 in xz2s
        push!(stuff, Primitive(xz2, material, nothing))
    end

    # YZs
    yz1s = Rectangle(Pnt2(p_min.y, p_min.z), Pnt2(p_max.y, p_max.z), p_max.x, 1, sc, false, nothing)
    for yz1 in yz1s
        push!(stuff, Primitive(yz1, material, nothing))
    end
    yz2s = Rectangle(Pnt2(p_min.y, p_min.z), Pnt2(p_max.y, p_max.z), p_min.x, 1, sc, false, nothing)
    for yz2 in yz2s
        push!(stuff, Primitive(yz2, material, nothing))
    end

    return stuff
end 

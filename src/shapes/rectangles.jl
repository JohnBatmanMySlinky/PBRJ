function Rectangle(MIN::Pnt2, MAX::Pnt2, k::Float64, axis::Int64, sc::ShapeCore)::Vector{Triangle}
    if axis == 1
        return construct_triangle_mesh(
            sc,
            2,
            4,
            [Pnt3(k, MIN.x, MIN.y), Pnt3(k, MAX.x, MAX.y), Pnt3(k, MIN.x, MAX.y), Pnt3(k, MAX.x, MIN.y)],
            [1,2,3,1,2,4],
            [Nml3(0,-1,0), Nml3(0,-1,0), Nml3(0,-1,0), Nml3(0,-1,0)],
            [Pnt2(0,0), Pnt2(1,1), Pnt2(0,1), Pnt2(1,0)],
        )
    elseif axis == 2
        return construct_triangle_mesh(
            sc,
            2,
            4,
            [Pnt3(MIN.x, k, MIN.y), Pnt3(MAX.x, k, MAX.y), Pnt3(MIN.x, k, MAX.y), Pnt3(MAX.x, k, MIN.y)],
            [1,2,3,1,2,4],
            [Nml3(0,-1,0), Nml3(0,-1,0), Nml3(0,-1,0), Nml3(0,-1,0)],
            [Pnt2(0,0), Pnt2(1,1), Pnt2(0,1), Pnt2(1,0)],
        )
    elseif axis == 3
        return construct_triangle_mesh(
            sc,
            2,
            4,
            [Pnt3(MIN.x, MIN.y, k), Pnt3(MAX.x, MAX.y, k), Pnt3(MIN.x, MAX.y, k), Pnt3(MAX.x, MIN.y, k)],
            [1,2,3,1,2,4],
            [Nml3(0,-1,0), Nml3(0,-1,0), Nml3(0,-1,0), Nml3(0,-1,0)],
            [Pnt2(0,0), Pnt2(1,1), Pnt2(0,1), Pnt2(1,0)],
        )
    else
        @assert false
    end
end

function Box(MIN::Pnt3, MAX::Pnt3, sc::ShapeCore)::Vector{Triangle}
    top = Rectangle(
        Pnt2(MIN.x, MIN.z),
        Pnt2(MAX.x, MAX.z),
        MAX.y,
        2,
        sc
    )
    bottom = Rectangle(
        Pnt2(MIN.x, MIN.z),
        Pnt2(MAX.x, MAX.z),
        MIN.y,
        2,
        sc
    )
    front = Rectangle(
        Pnt2(MIN.y, MIN.z),
        Pnt2(MAX.y, MAX.z),
        MIN.x,
        1,
        sc
    )
    back = Rectangle(
        Pnt2(MIN.y, MIN.z),
        Pnt2(MAX.y, MAX.z),
        MAX.x,
        1,
        sc
    )
    left = Rectangle(
        Pnt2(MIN.x, MIN.y),
        Pnt2(MAX.x, MAX.y),
        MIN.z,
        3,
        sc
    )
    right = Rectangle(
        Pnt2(MIN.x, MIN.y),
        Pnt2(MAX.x, MAX.y),
        MAX.z,
        3,
        sc
    )
    return vcat(top, bottom, left, right, front, back)
end
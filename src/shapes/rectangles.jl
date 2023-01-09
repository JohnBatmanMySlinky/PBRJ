function Rectangle(MIN::Pnt2, MAX::Pnt2, k::Float64, axis::Int64, sc::ShapeCore, flip_normals::Bool, alpha_mask::Maybe{Texture})::Vector{Triangle}
    flip = flip_normals ? -1 : 1
    if axis == 1
        return construct_triangle_mesh(
            sc,
            2,
            4,
            [Pnt3(k, MIN.x, MIN.y), Pnt3(k, MAX.x, MAX.y), Pnt3(k, MIN.x, MAX.y), Pnt3(k, MAX.x, MIN.y)],
            # BE REALLY CAREFUL OF YOUR WINDING ORDER
            [1,2,3,1,4,2],
            [Nml3(1,0,0)*flip, Nml3(1,0,0)*flip, Nml3(1,0,0)*flip, Nml3(1,0,0)*flip],
            [Pnt2(0,0), Pnt2(1,1), Pnt2(0,1), Pnt2(1,0)],
            alpha_mask
        )
    elseif axis == 2
        return construct_triangle_mesh(
            sc,
            2,
            4,
            [Pnt3(MIN.x, k, MIN.y), Pnt3(MAX.x, k, MAX.y), Pnt3(MIN.x, k, MAX.y), Pnt3(MAX.x, k, MIN.y)],
            # BE REALLY CAREFUL OF YOUR WINDING ORDER
            [1,2,3,1,4,2],
            [Nml3(0,1,0)*flip, Nml3(0,1,0)*flip, Nml3(0,1,0)*flip, Nml3(0,1,0)*flip],
            [Pnt2(0,0), Pnt2(1,1), Pnt2(0,1), Pnt2(1,0)],
            alpha_mask
        )
    elseif axis == 3
        return construct_triangle_mesh(
            sc,
            2,
            4,
            [Pnt3(MIN.x, MIN.y, k), Pnt3(MAX.x, MAX.y, k), Pnt3(MIN.x, MAX.y, k), Pnt3(MAX.x, MIN.y, k)],
            # BE REALLY CAREFUL OF YOUR WINDING ORDER
            [1,2,3,1,4,2],
            [Nml3(0,0,1)*flip, Nml3(0,0,1)*flip, Nml3(0,0,1)*flip, Nml3(0,0,1)*flip],
            [Pnt2(0,0), Pnt2(1,1), Pnt2(0,1), Pnt2(1,0)],
            alpha_mask
        )
    else
        @assert false
    end
end

function Box(MIN::Pnt3, MAX::Pnt3, sc::ShapeCore, alpha_mask::Maybe{Texture})::Vector{Triangle}
    top = Rectangle(
        Pnt2(MIN.x, MIN.z),
        Pnt2(MAX.x, MAX.z),
        MAX.y,
        2,
        sc,
        false,
        alpha_mask
    )
    bottom = Rectangle(
        Pnt2(MIN.x, MIN.z),
        Pnt2(MAX.x, MAX.z),
        MIN.y,
        2,
        sc,
        true,
        alpha_mask
    )
    front = Rectangle(
        Pnt2(MIN.y, MIN.z),
        Pnt2(MAX.y, MAX.z),
        MIN.x,
        1,
        sc,
        false,
        alpha_mask
    )
    back = Rectangle(
        Pnt2(MIN.y, MIN.z),
        Pnt2(MAX.y, MAX.z),
        MAX.x,
        1,
        sc,
        true,
        alpha_mask
    )
    left = Rectangle(
        Pnt2(MIN.x, MIN.y),
        Pnt2(MAX.x, MAX.y),
        MIN.z,
        3,
        sc,
        false,
        alpha_mask
    )
    right = Rectangle(
        Pnt2(MIN.x, MIN.y),
        Pnt2(MAX.x, MAX.y),
        MAX.z,
        3,
        sc,
        true,
        alpha_mask
    )
    return vcat(top, bottom, left, right, front, back)
end
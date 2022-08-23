struct Scene
    lights::Vector{Light}
    b::BVHAccel
    bounds::Bounds3

    function Scene(lights::Vector{Light}, b::BVHAccel)
        new(lights, b, world_bounds(b))
    end
end

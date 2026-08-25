struct Scene
    lights::Vector{Handle{:Light}}
    b::BVHAccel
    bounds::Bounds3

    function Scene(lights::Vector{Light}, b::BVHAccel)
        new(to_light_handle.(lights), b, world_bounds(b))
    end
end

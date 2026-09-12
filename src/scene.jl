struct Scene
    lights::Vector{Handle{:Light}}
    b::AbstractBVHAccel
    bounds::Bounds3

    function Scene(lights::Vector{AbstractLight}, b::AbstractBVHAccel)
        new(to_light_handle.(lights), b, world_bounds(b))
    end
end

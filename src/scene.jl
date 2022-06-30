struct Scene
    lights::Vector{Light}
    b::BVHNode
    bounds::Bounds3

    function Scene(lights::Vector{Light}, b::BVHNode)
        new(lights, b, b.bounds)
    end
end

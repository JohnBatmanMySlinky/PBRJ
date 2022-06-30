struct Primitive
    shape::Shape
    material::Material
end

#####################################################
#### Basiclly just passing on calls to the ##########
#### underlying shape or material ###################
#####################################################

function Intersect!(gp::Primitive, ray::Ray)
    check, t, interaction = Intersect(gp.shape, ray)
    if !check
        return false, nothing, nothing
    end
    ray.tMax = t
    interaction.primitive = gp
    return true, t, interaction
end

function world_bounds(p::Primitive)::Bounds3
    return world_bounds(p.shape)
end
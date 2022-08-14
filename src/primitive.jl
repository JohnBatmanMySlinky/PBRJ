struct Primitive
    shape::Shape
    material::Material
    area_light::Maybe{Light}
end

#####################################################
#### Basiclly just passing on calls to the ##########
#### underlying shape or material ###################
#####################################################

function intersect!(gp::Primitive, ray::AbstractRay)
    check, t, interaction = intersect(gp.shape, ray)
    if !check
        return false, nothing, nothing
    end
    ray.tMax = t
    interaction.primitive = gp
    return true, t, interaction
end

function intersect_p(gp::Primitive, ray::AbstractRay)::Bool
    # TODO FIX JOHN HACK
    # What happens if an area light occludes an area light?
    if gp.area_light isa Nothing
        return intersect_p(gp.shape, ray)
    else
        return false
    end
end

function world_bounds(p::Primitive)::Bounds3
    return world_bounds(p.shape)
end
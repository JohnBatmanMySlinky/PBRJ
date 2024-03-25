struct Primitive
    shape::Shape
    material::Maybe{Material}
    area_light::Maybe{Light}
    mi::MediumInterface
end

function Primitive(s::Shape, m::Maybe{Material}, al::Maybe{Light})
    return Primitive(s, m, al, MediumInterface(nothing))
end

#####################################################
#### Basiclly just passing on calls to the ##########
#### underlying shape or material ###################
#####################################################

function intersect!(gp::Primitive, ray::AbstractRay, shadow_ray::Bool=false)::Tuple{Bool, Maybe{Float64}, Maybe{SurfaceInteraction}}
    if shadow_ray && !(gp.area_light isa Nothing) # JOHN HACK
        # shadow rays can't intersect with lights
        return false, nothing, nothing
    else
        check, t, interaction = intersect(gp.shape, ray)
        if !check
            return false, nothing, nothing
        end
        ray.tMax = t
        interaction.primitive = gp
        if is_transition_medium(gp.mi)
            interaction.core.mi = gp.mi
        else
            interaction.core.mi = MediumInterface(ray.medium)
        end
        return true, t, interaction
    end
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
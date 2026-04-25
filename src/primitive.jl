struct Primitive
    shape::Shape
    material::Maybe{String}
    area_light::Maybe{Light}
    mi::MediumInterface
end

function Primitive(s::Shape, m::Maybe{String}, al::Maybe{Light})
    return Primitive(s, m, al, NO_MEDIUM_INTERFACE)
end

#####################################################
#### Basiclly just passing on calls to the ##########
#### underlying shape or material ###################
#####################################################

function intersect!(gp::Primitive, ray::AbstractRay, shadow_ray::Bool=false)::Tuple{Bool, Maybe{Float64}, Maybe{SurfaceInteraction}}
    ####################
    ### For party blob; my "shadow rays can't intersect stuf" was killnig me
    ### So I removed removed it (adding a false) - 
    ### leaving this note here so I cant un fuck this if other scenes get fucked
    #####################
    
    if shadow_ray && !(gp.area_light isa Nothing) && false
        # shadow rays can't intersect with lights
        return false, nothing, nothing
    else
        check, t, interaction = intersect(gp.shape, ray)
        if !check
            return false, nothing, nothing
        end
        ray.tMax = t
        interaction.primitive = gp
        new_mi = is_transition_medium(gp.mi) ? gp.mi : MediumInterface(ray.medium)
        interaction.core = Interaction(interaction.core.p, interaction.core.t, interaction.core.wo, interaction.core.n, new_mi)
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
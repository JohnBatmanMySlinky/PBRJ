struct Primitive
    shape::Handle{:Shape}
    material::Maybe{Handle{:Material}}
    area_light::Maybe{Handle{:Light}}
    mi::MediumInterface
end

# Accept a raw material name (resolved against MATERIAL_REGISTRY on first use,
# same convenience pattern as MediumInterface's constructors in medium2/common1.jl)
# or an already-resolved Handle{:Material}.
function Primitive(s::AbstractShape, m::Maybe{Union{String, Handle{:Material}}}, al::Maybe{AbstractLight})
    return Primitive(to_shape_handle(s), to_material_handle(m), to_light_handle(al), NO_MEDIUM_INTERFACE)
end

function Primitive(s::AbstractShape, m::Maybe{Union{String, Handle{:Material}}}, al::Maybe{AbstractLight}, mi::MediumInterface)
    return Primitive(to_shape_handle(s), to_material_handle(m), to_light_handle(al), mi)
end

#####################################################
#### Basiclly just passing on calls to the ##########
#### underlying shape or material ###################
#####################################################

# Narrow phase - just forward to the shape's hit test, no interaction.
function intersect_geom(gp::Primitive, ray::AbstractRay)::Tuple{Bool, Float64}
    return intersect_geom(gp.shape, ray)
end

# Broad phase - build the full `SurfaceInteraction` for a primitive the BVH
# has already chosen as the closest hit. This is the tail of the old
# `intersect!` below: run the shape's full `intersect` and patch in the
# shape handle, the owning primitive, and the medium interface.
#
# `ray.tMax` is opened to Inf for the shape call so the re-intersection of
# an already-known winner can't be lost to a 1-ULP `t <= tMax` rejection,
# then pinned to the hit t (the old post-hit contract) on the way out.
function finalize_intersection(gp::Primitive, ray::AbstractRay)::Tuple{Bool, Float64, Maybe{SurfaceInteraction}}
    saved = ray.tMax[]
    ray.tMax[] = Inf
    check, t, interaction = intersect(gp.shape, ray)
    if !check
        ray.tMax[] = saved
        return false, Inf, nothing
    end
    ray.tMax[] = t
    interaction.shape = gp.shape
    interaction.primitive = gp
    new_mi = is_transition_medium(gp.mi) ? gp.mi : MediumInterface(ray.medium)
    interaction.core = Interaction(interaction.core.p, interaction.core.t, interaction.core.wo, interaction.core.n, new_mi)
    return true, t, interaction
end

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
        ray.tMax[] = t
        interaction.shape = gp.shape
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
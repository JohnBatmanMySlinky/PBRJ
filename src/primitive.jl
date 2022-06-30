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

function compute_scattering!(p::GeometricPrimitive, si::SurfaceInteraction, allow_multiple_lobes::Bool, ::Type{T}) where T <: TransportMode
    if !(p.material isa Nothing)
        # evaluate the bsdf
        p.material(si, allow_multiple_lobes, T)
    end
    @assert (dot(si.core.n, si.shading.n)) >= Spectrum(0, 0, 0)
end
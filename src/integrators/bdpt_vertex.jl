# 16.3.1 Vertex Abstraction Layer

######################################
## Many definitions for vertex and co
######################################

# the four different kinds of vertices supported in pbrt.
@enum VertexType::UInt8 begin
    VTCamera  = 0b1
    VTLight   = 0b10
    VTSurface = 0b100
    VTMedium  = 0b1000
end

# EndpointInteraction is a new interaction implementation that is only used in BDPT. 
# It records the path end point, ie a position on a light source or the lens of a cemera
# and stores a pointer to the camera or light in question
mutable struct EndpointInteraction
    interaction::Interaction
    # John hack, maybe{} instead of unions
    camera::Maybe{Camera}
    light::Maybe{Light}
end

mutable struct Vertex
    type::VertexType
    beta::Spectrum
    # John hack, maybe{} instead of unions
    ei::Maybe{EndpointInteraction}
    # mi::MediumInteraction --> no medium 
    si::Maybe{SurfaceInteraction}
    delta::Bool
    pdf_fwd::Float64
    pdf_rev::Float64

    function Vertex(type::VertexType, beta::Spectrum, ei::Maybe{EndpointInteraction}, si::Maybe{SurfaceInteraction})
        @assert !((ei isa Nothing) & (si isa Nothing))
        return new(
            type, beta, ei, si, false, 0.0, 0.0
        )
    end
end

####################
### MANY utility functions & constructors
####################

############ EndpointInteraction constructors
function EndpointInteraction()::EndpointInteraction
    return EndpointInteraction(Interaction(), nothing, nothing)
end
function EndpointInteraction(ray::AbstractRay)::EndpointInteraction
    return EndpointInteraction(Interaction(ray), nothing, nothing)
end
function EndpointInteraction(camera::Camera, ray::AbstractRay)::EndpointInteraction
    return EndpointInteraction(Interaction(ray), camera, nothing)
end
function EndpointInteraction(it::Interaction, camera::Camera)::EndpointInteraction
    return EndpointInteraction(it, camera, nothing)
end
function EndpointInteraction(light::Light, ray::AbstractRay, nml::Nml3)::EndpointInteraction
    return EndpointInteraction(Interaction(ray, nml), nothing, light)
end


############ Vertex constructors
# bdpt.h line 448
function create_camera_vertex(camera::Camera, ray::AbstractRay, beta::Spectrum)::Vertex
    return Vertex(
        VTCamera,
        beta,
        EndpointInteraction(camera, ray),
        nothing
    )
end
# bdpt.h line 453
function create_camera_vertex(camera::Camera, it::Interaction, beta::Spectrum)::Vertex
    return Vertex(
        VTCamera,
        beta,
        EndpointInteraction(it, camera),
        nothing
    )
end
# bdpt.h line 458
function create_light_vertex(light::Light, ray::AbstractRay, n::Nml3, le::Spectrum, pdf::Float64)::Vertex
    v = Vertex(
        VTLight,
        le,
        EndpointInteraction(light, ray, n),
        nothing
    )
    v.pdf_fwd = pdf
    return v
end
# bdpt.h line 482
function create_light_vertex(ei::EndpointInteraction, beta::Spectrum, pdf::Float64)::Vertex
    v = Vertex(
        VTLight,
        beta,
        ei,
        nothing
    )
    v.pdf_fwd = pdf
    return v
end
# bdpt.h line 466
function create_surface_vertex(si::SurfaceInteraction, beta::Spectrum, pdf_fwd::Float64, prev::Vertex)::Vertex
    v = Vertex(
        VTSurface,
        beta, 
        nothing,
        si
    )
    v.pdf_fwd = convert_density(prev, pdf_fwd, v)
    return v
end

############# Vertex Utilities
"""
indicates whether a vertex is associated with an infinite area light.
such vertices can be created by
    - sampling an emitted ray from an infinite area light
    - tracing a ray from the camera that escapes
if the latter case the vertex is marked with a VertexType::Light but ei.light stores a nullptr
"""
function is_infinite_light(v::Vertex)::Bool
    # in either case if VertexType isn't light, it isnt an infinite light
    if v.type != VTLight
        return false
    else
        # if we have a VTLight but null light --> case 2 --> true
        if v.ei.light isa Nothing
            return true
        else
            # if we have a VTLight and a light in ei, check type of light
            return v.ei.light.flags & LightInfinite
        end
    end
end

function is_on_surface(v::Vertex)::Bool
    return ng(v) != Nml3(0,0,0)
end

# JOHN HACK: Can I get away without get_interaction()? would be more type stable I think?
function p(v::Vertex)::Pnt3
    if v.type == VTSurface
        return v.si.core.p
    else
        return v.ei.interaction.p
    end
end
function ng(v::Vertex)::Nml3
    if v.type == VTSurface
        return v.si.core.n
    else
        return v.ei.interaction.n
    end
end
function ns(v::Vertex)::Nml3
    if v.type == VTSurface
        return v.si.shading.n
    else
        return v.ei.interaction.n
    end
end
function time(v::Vertex)::Float64
    if v.type == VTSurface
        return v.si.core.t
    else
        return v.ei.interaction.t
    end
end
function time(I::Union{EndpointInteraction, SurfaceInteraction})::Float64
    if I isa SurfaceInteraction
        return I.core.t
    elseif I isa EndpointInteraction
        return I.interaction.t
    else
        @assert false, "bad stuff"
    end
end

function is_connectible(v::Vertex)::Bool
    if v.type == VTMedium
        return true
    elseif v.type == VTLight
        return v.ei.light.flags & LightDeltaDirection # JOHN why is there a ==0???
    elseif v.type == VTCamera
        return true
    elseif v.type == VTSurface
        return num_components(v.si.bsdf, BSDF_DIFFUSE | BSDF_GLOSSY | BSDF_REFLECTION | BSDF_TRANSMISSION) > 0
    else
        @assert false, "bad"
    end
    return false # NOT REACHED
end

function get_interaction(v::Vertex)::Union{EndpointInteraction, SurfaceInteraction}
    if v.type == VTMedium
        return v.mi
    elseif v.type == VTSurface
        return v.si
    else
        return v.ei
    end
end

function get_interaction(I::Union{EndpointInteraction, SurfaceInteraction})::Interaction
    if I isa SurfaceInteraction
        return I.core
    elseif I isa EndpointInteraction
        return I.interaction
    else
        @assert false, "bad stuff"
    end
end

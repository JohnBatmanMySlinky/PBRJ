# 16.3.1 Vertex Abstraction Layer

######################################
## Many definitions for vertex and co
######################################

# the four different kinds of vertices supported in pbrt.
const VTCamera = Val{:VTCamera}
const VTLight = Val{:VTLight}
const VTSurface = Val{:VTSurface}
const VTMedium = Val{:VTMedium}
const VertexType = Union{VTCamera, VTLight, VTSurface, VTMedium}

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
    si::Maytbe{SurfaceInteraction}
    delta::Bool
    pdf_fwd::Float64
    pdf_rev::Float64

    function Vertex(type::VertexType, beta::Spectrum, ei::Maybe{EndpointInteraction}, si::Maybe{SurfaceInteraction})
    return new(
        type, beta, ei, si, false, 0.0, 0.0
    )
end

####################
### MANY utility functions & constructors
####################

############ EndpointInteraction constructors
function EndpointInteraction()::EndpointInteraction
    return EndpointInteraction(Interaction(), nothing, nothing)
end
function EndpointInteraction(camera::Camera, ray::Ray)::EndpointInteraction
    return EndpointInteraction(
        Interaction(ray), 
        camera, 
        nothing
    )
end


############ Vertex constructors
function create_camera_vertex(camera::Camera, ray::Ray, beta::Spectrum)::Vertex
    return Vertex(
        VTCamera,
        beta,
        EndpointInteraction(camera, ray),
        nothing
    )
end
# VTCreateLight()
# VTCreateMedium()
# VTCreateSurface()

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
    if v.VertexType != VTLight
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
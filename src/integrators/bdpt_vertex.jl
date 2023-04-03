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
function EndpointInteraction(it::Interaction, light::Light)::EndpointInteraction
    return EndpointInteraction(it, nothing, light)
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

function is_light(v::Vertex)::Bool
    # either it's a VTLight or it's a VTSurface with an area light
    return (v.type == VTLight) || ((v.type == VTSurface) && !(v.si.primitive.area_light isa Nothing))
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


################################## Sampling
function le(v1::Vertex, scene::Scene, v2::Vertex)::Spectrum
    !is_light(v1) && (return Spectrum(0.0))
    w = p(v2) - p(v1)
    (dot(w,w) == 0.0) && (return Spectrum(0.0))
    w = Vec3(normalize(w))
    if is_infinite_light(v1)
        # return emitted radiance for infinite light sources
        LL = Spectrum(0.0)
        for light in scene.lights
            if is_infinite_light(light)
                LL += le(light, Ray(p(v1), -w, time(v1), typemax(Float64)))
            end
        end
        return LL
    else
        light = v1.si.primitive.area_light
        # JOHN HACK, ignore nullptr check?
        return L(light, v1.si.shading.n, w) # JOHN HACK, is it shading normal here?
    end
end

function pdf_light_origin(sampled::Vertex, scene::Scene, v::Vertex, light_distr::Distribution1D, light_num::Int64)::Float64
    w = p(v) - p(sampled)
    (dot(w,w) == 0.0) && (return 0.0)
    w = Vec3(normalize(w))
    if is_infinite_light(sampled)
        return infinite_light_density(scene.lights, light_distr, w)
    else
        light = sampled.type == VTLight ? sampled.ei.light : sampled.si.primitive.area_light
        pdf_choice = discrete_pdf(light_distr, light_num)
        pdf_pos, pdf_dir = pdf_le(light, Ray(p(sampled), w, time(sampled), typemax(Float64)), ng(sampled))
        return pdf_pos * pdf_choice
    end
end

function pdf_light(v0::Vertex, scene::Scene, v1::Vertex)::Float64
    w = Vec3(p(v1) - p(v0))
    invdist2 = 1/dot(w,w)
    w *= sqrt(invdist2)
    if is_infinite_light(v0)
        # Compute planar sampling density for infinite light sources
        worldradius = world_radius(scene.b)
        pdf_val = 1 / (pi * worldradius * worldradius)
    else
        light = v0.type == VTLight ? v0.ei.light : v1.si.primitive.area_light
        pdf_pos, pdf_dir = pdf_le(light, Ray(p(v0), w, time(v0), typemax(Float64)), ng(v0))
        pdf_val = pdf_dir * invdist2
    end
    if is_on_surface(v1)
        pdf_val *= abs(dot(ng(v1), w))
    end
    return pdf_val
end

function pdf(v0::Vertex, scene::Scene, prev::Maybe{Vertex}, next::Vertex)::Float64
    (v0.type == VTLight) && (return pdf_light(v0, scene, next))
    wn = p(next) - p(v0)
    (norm(wn)^2 == 0.0) && (return 0.0)
    wn = Vec3(normalize(wn))
    if !(prev isa Nothing)
        wp = p(prev) - p(v0)
        (norm(wp)^2 == 0.0) && (return 0.0)
        wp = Vec3(normalize(wp))
    end


    if v0.type == VTCamera
        _, pdf_val = pdf_we(v0.ei.camera, spawn_ray(v0.ei.interaction, wn))
    elseif v0.type == VTSurface
        pdf_val = compute_pdf(v0.si.bsdf, wp, wn, BSDF_ALL) # JOHN HACK do we need BSDF all?
    elseif v0.type == VTMedium
        @assert false # un-implemented
    else
        @assert false
    end
    return convert_density(v0, pdf_val, next)
end

function f(v1::Vertex, v2::Vertex, mode::Type{T})::Spectrum where T <: TransportMode
    wi = p(v2) - p(v1)
    (norm(wi)^2 == 0.0) && (return Spectrum(0.0))
    wi = Vec3(normalize(wi))
    if v1.type == VTSurface
        return v1.si.bsdf(v1.si.core.wo, wi) * correct_shading_normal(v1.si, v1.si.core.wo, wi, mode)
    elseif v1.type == VTMedium
        @assert false # NOT IMPLEMENTED
    else
        return Spectrum(0.0)
    end
end

function G(scene::Scene, sampler::AbstractSampler, v0::Vertex, v1::Vertex)::Spectrum
    d = Vec3(p(v0)-p(v1))
    g = 1.0 / norm(d)^2
    d *= sqrt(g)
    is_on_surface(v0) && (g *= abs(dot(ns(v0), d)))
    is_on_surface(v1) && (g *= abs(dot(ns(v1), d)))
    vis = VisibilityTester(
        get_interaction(get_interaction(v0)),
        get_interaction(get_interaction(v1)),
    )
    return g * tr(vis, scene.b, sampler)
end
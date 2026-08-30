# "The BSDF implementation stores only a limited number of individual BxDF components.
# It could easily be extended to allocate more space if more components were given to it,
# although this isn't necessary for any of the Material implementations in pbrt thus far,
# and the current limit of eight is plenty for almost all practical applications."

# PBR 9.1 BSDFs
# "The BSDF class represents a collection of BRDFs and BTDFs"
# Hence the tuple of BxDFs
struct BSDF{T <: Tuple} <: AbstractBSDF
    eta::Float64
    ng::Nml3
    ns::Nml3
    ss::Vec3
    ts::Vec3
    bxdfs::T

    function BSDF(si::SurfaceInteraction, eta::Float64, bxdfs::T) where T <: Tuple
        ng = si.core.n
        ns = si.shading.n
        ss = normalize(si.shading.dpdu)
        ts = cross(ns,ss)
        new{T}(
            eta, ng, ns, ss, ts, bxdfs
        )
    end
end

@inline function world_to_local(b::AbstractBSDF, v::Vec3)::Vec3
    return Vec3(dot(v, b.ss), dot(v, b.ts), dot(v, b.ns))
end

@inline function local_to_world(b::AbstractBSDF, v::Vec3)::Vec3
    return Vec3(
        b.ss.x * v.x + b.ts.x * v.y + b.ns.x * v.z,
        b.ss.y * v.x + b.ts.y * v.y + b.ns.y * v.z,
        b.ss.z * v.x + b.ts.z * v.y + b.ns.z * v.z
    )
end

# Equivalent to PBR's f()
function (b::AbstractBSDF)(woW::Vec3, wiW::Vec3, flags::UInt8=BSDF_ALL)::Spectrum
    # @info "BSDF::f woW: $woW, wiW: $wiW"
    wo = world_to_local(b, woW)
    wo.z == 0 && return spectrum_from_float(0.0)
    wi = world_to_local(b, wiW)
    # @info "BSDF::f wo: $wo, wi: $wi"
    reflect = (dot(wiW, b.ng) * dot(woW, b.ng)) > 0.0
    output = spectrum_from_float(0.0)
    for bxdf in b.bxdfs
        if (bxdf & flags) && ((reflect && (bxdf.type & BSDF_REFLECTION != 0)) || (!reflect && (bxdf.type & BSDF_TRANSMISSION != 0)))
            # @info "BSDF::f = $(f(bxdf, wo, wi)), wo = $wo, wi = $wi"
            output += f(bxdf, wo, wi)
        end
    end
    return output
end

# TODO
# add rho's

function sample_f(b::AbstractBSDF, wo_world::Vec3, u::Pnt2, type::UInt8)::Tuple{Vec3, Spectrum, Float64, UInt8}
    # Choose which BxDF to sample.
    matching_components = num_components(b, type)
    matching_components == 0 && return (Vec3(0), spectrum_from_float(0.0), 0.0, BSDF_NONE)
    component = min(floor(Int, u[1] * matching_components), matching_components - 1)

    # Locate the position (within b.bxdfs) of the chosen matching component.
    # We walk the tuple by position rather than indexing it with a runtime
    # value (b.bxdfs[i]) - a runtime index into a heterogeneous Tuple type
    # returns Union{<all element types>}, which boxes on every call. Walking
    # with `for x in b.bxdfs` instead lets the compiler unroll per-element
    # and keep each bxdf reference concretely typed.
    chosen_pos = -1
    count = component
    for (i, bxdf) in enumerate(b.bxdfs)
        if (bxdf & type)
            if count == 0
                chosen_pos = i
                break
            end
            count -= 1
        end
    end

    # Remap BxDF sample u to [0, 1)^2.
    u_remapped = Pnt2(
        min(u.x * matching_components - component, 1.0-eps()), u.y,
    )

    # Sample chosen BxDF.
    wo = world_to_local(b, wo_world)
    wo.z == 0 && return (Vec3(0), spectrum_from_float(0.0), 0, BSDF_NONE)

    sampled_type = BSDF_NONE
    is_specular = false
    wi = Vec3(0)
    f_val = spectrum_from_float(0.0)
    pdf_val = 0.0
    for (i, bxdf) in enumerate(b.bxdfs)
        if i == chosen_pos
            sampled_type = bxdf.type
            wi, f_val, pdf_val, sampled_type_tmp = sample_f(bxdf, wo, u_remapped, sampled_type)
            if !(sampled_type_tmp isa Nothing)
                sampled_type = sampled_type_tmp
            end
            is_specular = (bxdf.type & BSDF_SPECULAR) != 0
        end
    end

    pdf_val == 0 && return (Vec3(0), spectrum_from_float(0.0), 0, BSDF_NONE)

    wi_world = local_to_world(b, wi)
    # Compute overall PDF with all matching BxDFs.
    if !is_specular && matching_components > 1
        for (i, bxdf) in enumerate(b.bxdfs)
            if i != chosen_pos && (bxdf & type)
                pdf_val += compute_pdf(bxdf, wo, wi)
            end
        end
    end
    matching_components > 1 && (pdf_val /= matching_components)
    # Compute value of BSDF for sampled direction.
    if !is_specular
        reflect = (dot(wi_world, b.ng) * dot(wo_world, b.ng)) > 0
        f_val = spectrum_from_float(0.0, 0.0, 0.0)
        for bxdf_i in b.bxdfs
            if ((bxdf_i & type) && ((reflect && (bxdf_i.type & BSDF_REFLECTION != 0)) || (!reflect && (bxdf_i.type & BSDF_TRANSMISSION != 0))))
                f_val += f(bxdf_i, wo, wi)
            end
        end
    end
    return wi_world, f_val, pdf_val, sampled_type
end

function compute_pdf(b::AbstractBSDF, wo_world::Vec3, wi_world::Vec3, flags::UInt8,)::Float64
    # @info "HUH - $(length(b.bxdfs))"
    isempty(b.bxdfs) && return 0.0

    wo = world_to_local(b, wo_world)
    wo.z == 0 && return 0.0

    wi = world_to_local(b, wi_world)
    pdf = 0
    matching_components = 0
    for bxdf in b.bxdfs
        if bxdf & flags
            matching_components += 1
            # @info "bxdf: $bxdf"
            pdf += compute_pdf(bxdf, wo, wi)
        end
    end
    return matching_components > 0 ? pdf / matching_components : 0
end

function num_components(b::AbstractBSDF, flags::UInt8)::Int64
    num = 0
    for bxdf in b.bxdfs
        if bxdf & flags
            num += 1
        end
    end
    return num
end

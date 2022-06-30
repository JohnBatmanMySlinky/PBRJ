# "The BSDF implementation stores only a limited number of individual BxDF components. 
# It could easily be extended to allocate more space if more components were given to it, 
# although this isn’t necessary for any of the Material implementations in pbrt thus far, 
# and the current limit of eight is plenty for almost all practical applications."
const MAX_BxDF = UInt8(8)

# PBR 9.1 BSDFs
# "The BSDF class represents a collection of BRDFs and BTDFs"
# Hence the vector of BxDFs
mutable struct BSDF <: AbstractBSDF
    eta::Float64
    ng::Nml3
    ns::Nml3
    ss::Vec3
    ts::Vec3
    n_bxdfs::UInt8
    bxdfs::Vector{B} where B <: AbstractBxDF

    function BSDF(si::SurfaceInteraction, eta::Float64 = 1.0)
        ng = si.core.n
        ns = si.shading.n
        ss = normalize(si.shading.dpdu)
        ts = cross(ns,ss)
        new(
            eta, ng, ns, ss, ts, UInt8(0),
            Vector{B where B <: AbstractBxDF}(undef, MAX_BxDF),
        )
    end
end


function add!(b::BSDF, x::B) where B <: AbstractBxDF
    @assert b.n_bxdfs < MAX_BxDF
    b.n_bxdfs += 1
    b.bxdfs[b.n_bxdfs] = x
end

function world_to_local(b::BSDF, v::Vec3)
    return Vec3(dot(v, b.ss), dot(v, b.ts), dot(v, b.ns))
end

function local_to_world(b::BSDF, v::Vec3)
    return Mat3([b.ss b.ts b.ns]) * v
end

# Equivalent to PBR's f()
function (b::BSDF)(woW::Vec3, wiW::Vec3, flags::UInt8=BSDF_ALL)::Spectrum
    wo = world_to_local(b, woW)
    if wo.z == 0
        return Spectrum(0, 0, 0)
    end
    wi = world_to_local(b, wiW)
    
    reflect = (dot(wiW, b.ng) * dot(woW, b.ng)) > 0 

    output = Spectrum(0, 0, 0)
    for i in 1:b.n_bxdfs
        bxdf = b.bxdfs[i]
        if (bxdf & flags) && ((reflect && (bxdf.type & BSDF_REFLECTION != 0)) || (!reflect && (bxdf.type & BSDF_TRANSMISSION != 0)))
            output += bxdf(wo, wi)
        end
    end
    return output
end

# TODO 
# add rho's

function sample_f(b::BSDF, wo_world::Vec3, u::Pnt2, type::UInt8)::Tuple{Vec3, Spectrum, Float64, UInt8}
    # Choose which BxDF to sample.
    matching_components = num_components(b, type)
    if matching_components == 0
        return (
            Vec3(0, 0, 0), Spectrum(0, 0, 0), 0, BSDF_NONE,
        )
    end
    component = min(
        max(1, Int64(ceil(u[1] * matching_components))),
        matching_components,
    )
    # Get BxDF for chosen component.
    count = component
    component -= 1
    bxdf = nothing
    for i in 1:b.n_bxdfs
        if b.bxdfs[i] & type
            if count == 1
                bxdf = b.bxdfs[i]
                break
            end
            count -= 1
        end
    end
    @assert bxdf ≢ nothing "n bxdfs $(b.n_bxdfs), component $component, count $count"
    # Remap BxDF sample u to [0, 1)^2.
    u_remapped = Pnt2(
        min(u[1] * matching_components - component, 1), u[2],
    )
    # Sample chosen BxDF.
    wo = world_to_local(b, wo_world)
    if wo[3] == 0
        return (
            Vec3(0, 0, 0), Spectrum(0, 0, 0), 0, BSDF_NONE,
        )   
    end

    # TODO when to update sampled type
    sampled_type = bxdf.type
    wi, pdf, f, sampled_type_tmp = sample_f(bxdf, wo, u_remapped)
    if sampled_type_tmp ≢ nothing
        sampled_type = sampled_type_tmp
    end

    if pdf == 0
        return (
            Vec3(0, 0, 0), Spectrum(0, 0, 0), 0, BSDF_NONE,
        )
    end
    wi_world = local_to_world(b, wi)
    # Compute overall PDF with all matching BxDFs.
    if !(bxdf.type & BSDF_SPECULAR != 0) && matching_components > 1
        for i in 1:b.n_bxdfs
            if b.bxdfs[i] != bxdf && b.bxdfs[i] & type
                pdf += compute_pdf(b.bxdfs[i], wo, wi)
            end
        end
    end
    matching_components > 1 && (pdf /= matching_components)
    # Compute value of BSDF for sampled direction.
    if !(bxdf.type & BSDF_SPECULAR != 0)
        reflect = ((wi_world ⋅ b.ng) * (wo_world ⋅ b.ng)) > 0
        f = RGBSpectrum(0f0)
        for i in 1:b.n_bxdfs
            bxdf = b.bxdfs[i]
            if ((bxdf & type) && ((reflect && (bxdf.type & BSDF_REFLECTION != 0)) || (!reflect && (bxdf.type & BSDF_TRANSMISSION != 0))))
                f += bxdf(wo, wi)
            end
        end
    end

    return wi_world, f, pdf, sampled_type
end

function compute_pdf(b::BSDF, wo_world::Vec3, wi_world::Vec3, flags::UInt8,)::Float64
    if b.n_bxdfs == 0
        return 0
    end
    wo = world_to_local(b, wo_world)
    if wo[3] == 0
        return 0
    end
    wi = world_to_local(b, wi_world)
    pdf = 0
    matching_components = 0
    for i in 1:b.n_bxdfs
        if b.bxdfs[i] & flags
            matching_components += 1
            pdf += compute_pdf(b.bxdfs[i], wo, wi)
        end
    end
    return matching_components > 0 ? pdf / matching_components : 0
end

function num_components(b::BSDF, flags::UInt8)::Int64
    num = 0
    for i in 1:b.n_bxdfs
        if b.bxdfs[i] & flags
            num += 1
        end
    end
    return num
end
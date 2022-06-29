# "The BSDF implementation stores only a limited number of individual BxDF components. 
# It could easily be extended to allocate more space if more components were given to it, 
# although this isn’t necessary for any of the Material implementations in pbrt thus far, 
# and the current limit of eight is plenty for almost all practical applications."
const MAX_BxDF = UInt8(8)

# PBR 9.1 BSDFs
# "The BSDF class represents a collection of BRDFs and BTDFs"
# Hence the vector of BxDFs
mutable struct BSDF
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
        bxdf = b.bsdfs[i]
        if (bxdf & flags) && ((reflect && (bxdf.type & BSDF_REFLECTION != 0)) || (!reflect && (bxdf.type & BSDF_TRANSMISSION != 0)))
            output += bxdf(wo, wi)
        end
    end
    return output
end

# TODO 
# add rho's
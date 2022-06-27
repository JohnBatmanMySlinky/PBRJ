const MAX_BxDF = UInt8(8)

mutable struct BSDF
    eta::Float64
    ng::Nml3
    ns::Nml3
    ss::Vec3
    ts::Vec3
    n_bxdfs::UInt8
    bxdfs::Vector{B} where B <: AbstractBxDF

    function BSDF(si::SurfaceInteraction, eta::Float364 = 1.0)
        ng = si.core.n
        ns = si.shading.n
        ss = normalize(si.shading.∂p∂u)
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

function local_to_world(b::BSDF, v::Vec3f0)
    return Mat3([b.ss b.ts b.ns]) * v
end

function (b::BSDF)(
    wo_world::Vec3f0, wi_world::Vec3f0, flags::UInt8 = BSDF_ALL,
)::RGBSpectrum
    # Transform world-space direction vectors to local BSDF space.
    wo = world_to_local(b, wo_world)
    wo[3] ≈ 0f0 && return RGBSpectrum(0f0)
    wi = world_to_local(b, wi_world)
    # Determine whether to use BRDFs or BTDFs.
    reflect = ((wi_world ⋅ b.ng) * (wo_world ⋅ b.ng)) > 0

    output = RGBSpectrum(0f0)
    for i in 1:b.n_bxdfs
        bxdf = b.bxdfs[i]
        if ((bxdf & flags) && (
            (reflect && (bxdf.type & BSDF_REFLECTION != 0)) ||
            (!reflect && (bxdf.type & BSDF_TRANSMISSION != 0))
        ))
            output += bxdf(wo, wi)
        end
    end
    output
end

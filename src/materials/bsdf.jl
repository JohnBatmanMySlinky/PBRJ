const MAX_BxDF = UInt8(8)

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

function local_to_world(b::BSDF, v::Vec3)
    return Mat3([b.ss b.ts b.ns]) * v
end


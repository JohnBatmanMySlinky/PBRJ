struct Fourier{BM <: Maybe{AbstractTexture{Float64}}} <: Material
    bsdf_table::FourierBSDFTable
    bump_map::BM
    name::String

    function Fourier(
        name::String,
        path::String,
        bump_map::BM=nothing,
    ) where BM <: Maybe{AbstractTexture{Float64}}
        return new{BM}(read_fourier_bsdf_table(path), bump_map, name)
    end
end

# Equivalent to PBR's ComputeScatteringFunction
function (m::Fourier)(si::SurfaceInteraction, allow_multiple_lobes::Bool, mode::Type{T}) where T <: TransportMode
    # if bump map, update si
    if !(m.bump_map isa Nothing)
        bump!(m, si)
    end
    
    si.bsdf = BSDF(si, 1.0, (FourierBSDF(m.bsdf_table, mode, BSDF_REFLECTION | BSDF_TRANSMISSION | BSDF_GLOSSY),))
end
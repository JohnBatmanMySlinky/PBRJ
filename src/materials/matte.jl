# PBR 9.2.1 Matte Material
struct Matte{
        K <: AbstractTexture{Spectrum}, 
        S <: AbstractTexture{Float64}, 
        B <: Maybe{AbstractTexture{Float64}}
    } <: Material
    Kd::K
    sigma::S
    bump_map::B
    name::String

    function Matte(
        name::String,
        k::K=ConstantTexture(spectrum_from_float(0.5, 0.5, 0.5)),
        s::S=ConstantTexture(0.0),
        b::B=nothing
    )::Matte where {
        K <: AbstractTexture{Spectrum},
        S <: AbstractTexture{Float64},
        B <: Maybe{AbstractTexture{Float64}}
    }
        return new{K, S, B}(k, s, b, name)
    end
end

# Equivalent to PBR's ComputeScatteringFunction
function (m::Matte)(si::SurfaceInteraction, ::Bool, ::Type{T}) where T <: TransportMode
    # if bump map, update si
    if !(m.bump_map isa Nothing)
        bump!(m, si)
    end

    r = m.Kd(si)

    # TODO implement black body check
    sigma = clamp(m.sigma(si), 0, 90)
    if sigma == 0.0
        si.bsdf = BSDF(si, 1.0, (LambertianReflection(Spectrum(r)),))
    else
        si.bsdf = BSDF(si, 1.0, (OrenNayarReflection(r, sigma),))
    end
end

function albedo(m::Matte, si::SurfaceInteraction)::Spectrum
    return m.Kd(si)
end
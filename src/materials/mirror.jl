struct Mirror <: Material
    Kr::AbstractTexture{Spectrum}
    bump_map::Maybe{AbstractTexture{Float64}}

    function Mirror(
        Kr::AbstractTexture{Spectrum}=ConstantTexture(spectrum_from_float(1.0)),
        bump_map::Maybe{AbstractTexture{Float64}}=nothing
    )
        return new(Kr, bump_map)
    end
end

function (m::Mirror)(si::SurfaceInteraction, ::Bool, ::Type{T}) where T <: TransportMode
    # if bump map, update si
    if !(m.bump_map isa Nothing)
        bump!(m, si)
    end

    si.bsdf = BSDF(si)
    r = clamp.(m.Kr(si), 0, 1)
    add!(si.bsdf, SpecularReflection(r, FresnelNoOp()))
end
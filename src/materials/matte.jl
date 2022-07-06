# PBR 9.2.1 Matte Material
struct Matte <: Material
    Kd::Texture
    sigma::Texture
end

# Equivalent to PBR's ComputeScatteringFunction
function (m::Matte)(si::SurfaceInteraction, ::Bool, ::Type{T}) where T <: TransportMode
    # BUMP MAPPING ISN'T Implemented
    si.bsdf = BSDF(si)
    r = Spectrum(clamp.(m.Kd(si),0,1)...)

    # TODO implement black body check
    sigma = clamp.(m.sigma(si), 0, 90)
    if sigma == Pnt3(0, 0, 0)
        add!(si.bsdf, LambertianReflection(r))
    else
        print("OrenNayer isn't implemented")
        @assert False
    end
end
struct Mirror <: Material
    Kr::Texture
end

function (m::Mirror)(si::SurfaceInteraction, ::Bool, ::Type{T}) where T <: TransportMode
    si.bsdf = BSDF(si)
    r = spectrum_from_float(clamp.(m.Kr(si), 0, 1)...)
    add!(si.bsdf, SpecularReflection(r, FresnelNoOp()))
end
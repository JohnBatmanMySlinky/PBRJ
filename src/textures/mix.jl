struct MixAddTexture <: Texture
    a::Texture
    b::Texture
end

function (t::MixAddTexture)(si::SurfaceInteraction)
    a_tex = t.a(si)
    b_tex = t.b(si)
    return clamp.(a_tex + b_tex, 0, 1)
end
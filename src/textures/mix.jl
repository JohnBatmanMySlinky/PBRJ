struct MixAddTexture <: Texture
    a::Texture
    b::Texture
end

function (t::MixAddTexture)(si::SurfaceInteraction)
    return t(si.uv)
end

function (t::MixAddTexture)(uv::Pnt2)
    a_tex = t.a(uv)
    b_tex = t.b(uv)
    return clamp.(a_tex + b_tex, 0, 1)
end
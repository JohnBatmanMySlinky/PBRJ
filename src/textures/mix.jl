struct MixAddTexture <: Texture
    a::Texture
    b::Texture
end

function (t::MixAddTexture)(si::SurfaceInteraction)
    a_tex = t.a(si)
    b_tex = t.b(si)
    return clamp.(a_tex + b_tex, 0, 1)
end

struct MixDirectionTexture <: Texture
    a::Texture
    b::Texture
    dir::Vec3
    function MixDirectionTexture(a::Texture, b::Texture, dir::Vec3)
        return new(a,b,normalize(dir))
    end
end

function (t::MixDirectionTexture)(si::SurfaceInteraction)
    # JOHN HACK
    # SHADING OR GEOMETRIC N?
    amt = abs(dot(si.core.n, t.dir))
    return amt * t.a(si) + (1.0 - amt) * t.b(si)
end

struct MixMultTexture <: Texture
    a::Texture
    b::Texture
end

function (t::MixMultTexture)(si::SurfaceInteraction)
    a_tex = t.a(si)
    b_tex = t.b(si)
    return a_tex * b_tex
end
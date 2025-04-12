struct MixAddTexture{T} where T <: Union{Float64, Spectrum}
    a::Texture{T}
    b::Texture{T}
end

function (t::MixAddTexture{T})(si::SurfaceInteraction)::T where T <: Union{Float64, Spectrum}
    a_tex = t.a(si)
    b_tex = t.b(si)
    return T == Float64 ? clamp(a_tex + b_tex, 0.0, 1.0) : clamp.(a_tex + b_tex, 0.0, 1.0)
end

struct MixDirectionTexture{T} where T <: Union{Float64, Spectrum}
    a::Texture{T}
    b::Texture{T}
    dir::Vec3
    function MixDirectionTexture{T}(a::Texture{T}, b::Texture{T}, dir::Vec3) where T <: Union{Float64, Spectrum}
        return new{T}(a, b, normalize(dir))
    end
end

function (t::MixDirectionTexture{T})(si::SurfaceInteraction)::T where T <: Union{Float64, Spectrum}
    amt = abs(dot(si.core.n, t.dir))
    return amt * t.a(si) + (1.0 - amt) * t.b(si)
end

struct MixMultTexture{T} where T <: Union{Float64, Spectrum}
    a::Texture{T}
    b::Texture{T}
end

function (t::MixMultTexture{T})(si::SurfaceInteraction)::T where T <: Union{Float64, Spectrum}
    a_tex = t.a(si)
    b_tex = t.b(si)
    return a_tex * b_tex
end
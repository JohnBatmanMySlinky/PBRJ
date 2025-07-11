struct MixAddTexture{T <: Union{Float64, Spectrum}} <: AbstractTexture{T}
    a::AbstractTexture{T}
    b::AbstractTexture{T}
    name::Maybe{String}

    function MixAddTexture(a::AbstractTexture{T}, b::AbstractTexture{T}, name::Maybe{String}=nothing)::AbstractTexture{T} where T <: Union{Float64, Spectrum}
        return new{T}(a, b, name)
    end
end

function (t::MixAddTexture{T})(si::SurfaceInteraction)::T where T <: Union{Float64, Spectrum}
    a_tex = t.a(si)
    b_tex = t.b(si)
    return T == Float64 ? clamp(a_tex + b_tex, 0.0, 1.0) : clamp.(a_tex + b_tex, 0.0, 1.0)
end

struct MixDirectionTexture{T <: Union{Float64, Spectrum}} <: AbstractTexture{T}
    a::AbstractTexture{T}
    b::AbstractTexture{T}
    dir::Vec3
    name::Maybe{String}

    function MixDirectionTexture(a::AbstractTexture{T}, b::AbstractTexture{T}, dir::Vec3, name::Maybe{String}=nothing)::MixDirectionTexture{T} where T <: Union{Float64, Spectrum}
        return new{T}(a, b, normalize(dir), name)
    end
end

function (t::MixDirectionTexture{T})(si::SurfaceInteraction)::T where T <: Union{Float64, Spectrum}
    amt = abs(dot(si.core.n, t.dir))
    return amt * t.a(si) + (1.0 - amt) * t.b(si)
end

struct MixMultTexture{T <: Union{Float64, Spectrum}} <: AbstractTexture{T}
    a::AbstractTexture{T}
    b::AbstractTexture{T}
    name::Maybe{String}

    function MixMultTexture(a::AbstractTexture{T}, b::AbstractTexture{T}, name::Maybe{String}=nothing)::MixMultTexture{T} where T <: Union{Float64, Spectrum}
        return new{T}(a, b, name)
    end
end

function (t::MixMultTexture{T})(si::SurfaceInteraction)::T where T <: Union{Float64, Spectrum}
    a_tex = t.a(si)
    b_tex = t.b(si)
    return a_tex * b_tex
end
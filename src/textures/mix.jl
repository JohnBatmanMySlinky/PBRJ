struct MixAddTexture{T <: Union{Float64, Spectrum}, A <: AbstractTexture{T}, B <: AbstractTexture{T}} <: AbstractTexture{T}
    a::A
    b::B
    hash::Maybe{UInt32}

    function MixAddTexture(
        a::A, 
        b::B, 
        name::Maybe{String}=nothing
    ) where {T <: Union{Float64, Spectrum}, A <: AbstractTexture{T}, B <: AbstractTexture{T}}
        return new{T, A, B}(a, b, crc32c(name))
    end
end

# Now the function calls can be fully optimized since Julia knows the concrete types
@inline function (t::MixAddTexture{Float64, A, B})(si::SurfaceInteraction)::Float64 where {A, B}
    a_tex = t.a(si)  # Julia knows exactly which texture type this is
    b_tex = t.b(si)  # Julia knows exactly which texture type this is
    return clamp(a_tex + b_tex, 0.0, 1.0)
end

@inline function (t::MixAddTexture{Spectrum, A, B})(si::SurfaceInteraction)::Spectrum where {A, B}
    a_tex = t.a(si)  # Julia knows exactly which texture type this is
    b_tex = t.b(si)  # Julia knows exactly which texture type this is
    return clamp.(a_tex + b_tex, 0.0, 1.0)
end

struct MixMinTexture{T <: Union{Float64, Spectrum}, A <: AbstractTexture{T}, B <: AbstractTexture{T}} <: AbstractTexture{T}
    a::A
    b::B
    hash::Maybe{UInt32}

    function MixMinTexture(
        a::A, 
        b::B, 
        name::Maybe{String}=nothing
    ) where {T <: Union{Float64, Spectrum}, A <: AbstractTexture{T}, B <: AbstractTexture{T}}
        return new{T, A, B}(a, b, crc32c(name))
    end
end

# Specialized implementations for each value type
@inline function (t::MixMinTexture{Float64, A, B})(si::SurfaceInteraction)::Float64 where {A, B}
    a_tex = t.a(si)  # Julia knows exactly which texture type this is
    b_tex = t.b(si)  # Julia knows exactly which texture type this is
    return clamp(min(a_tex, b_tex), 0.0, 1.0)
end

@inline function (t::MixMinTexture{Spectrum, A, B})(si::SurfaceInteraction)::Spectrum where {A, B}
    a_tex = t.a(si)  # Julia knows exactly which texture type this is
    b_tex = t.b(si)  # Julia knows exactly which texture type this is
    return clamp.(min.(a_tex, b_tex), 0.0, 1.0)
end

struct MixDirectionTexture{T <: Union{Float64, Spectrum}, A <: AbstractTexture{T}, B <: AbstractTexture{T}} <: AbstractTexture{T}
    a::A
    b::B
    dir::Vec3
    hash::Maybe{UInt32}

    function MixDirectionTexture(
        a::A, 
        b::B, 
        dir::Vec3, 
        name::Maybe{String}=nothing
    ) where {T <: Union{Float64, Spectrum}, A <: AbstractTexture{T}, B <: AbstractTexture{T}}
        return new{T, A, B}(a, b, normalize(dir), crc32c(name))
    end
end

# Specialized implementations for each value type
@inline function (t::MixDirectionTexture{Float64, A, B})(si::SurfaceInteraction)::Float64 where {A, B}
    amt = abs(dot(si.core.n, t.dir))
    a_tex = t.a(si)  # Julia knows exactly which texture type this is
    b_tex = t.b(si)  # Julia knows exactly which texture type this is
    return amt * a_tex + (1.0 - amt) * b_tex
end

@inline function (t::MixDirectionTexture{Spectrum, A, B})(si::SurfaceInteraction)::Spectrum where {A, B}
    amt = abs(dot(si.core.n, t.dir))
    a_tex = t.a(si)  # Julia knows exactly which texture type this is
    b_tex = t.b(si)  # Julia knows exactly which texture type this is
    return amt * a_tex + (1.0 - amt) * b_tex
end

struct MixMultTexture{T <: Union{Float64, Spectrum}, A <: AbstractTexture{T}, B <: AbstractTexture{T}} <: AbstractTexture{T}
    a::A
    b::B
    hash::Maybe{UInt32}

    function MixMultTexture(
        a::A, 
        b::B, 
        name::Maybe{String}=nothing
    ) where {T <: Union{Float64, Spectrum}, A <: AbstractTexture{T}, B <: AbstractTexture{T}}
        return new{T, A, B}(a, b, crc32c(name))
    end
end

# Specialized implementations for each value type
@inline function (t::MixMultTexture{Float64, A, B})(si::SurfaceInteraction)::Float64 where {A, B}
    a_tex = t.a(si)  # Julia knows exactly which texture type this is
    b_tex = t.b(si)  # Julia knows exactly which texture type this is
    return a_tex * b_tex
end

@inline function (t::MixMultTexture{Spectrum, A, B})(si::SurfaceInteraction)::Spectrum where {A, B}
    a_tex = t.a(si)  # Julia knows exactly which texture type this is
    b_tex = t.b(si)  # Julia knows exactly which texture type this is
    return a_tex * b_tex
end

struct MixBlendTexture{T <: Union{Float64, Spectrum}, A <: AbstractTexture{T}, B <: AbstractTexture{T}} <: AbstractTexture{T}
    a::A
    b::B
    percent_A::Float64
    hash::Maybe{UInt32}

    function MixBlendTexture(
        a::A, 
        b::B, 
        percent_A::Float64,
        name::Maybe{String}=nothing
    ) where {T <: Union{Float64, Spectrum}, A <: AbstractTexture{T}, B <: AbstractTexture{T}}
        return new{T, A, B}(a, b, percent_A, crc32c(name))
    end
end

# Specialized implementations for each value type
@inline function (t::MixBlendTexture{Float64, A, B})(si::SurfaceInteraction)::Float64 where {A, B}
    a_tex = t.a(si)  # Julia knows exactly which texture type this is
    b_tex = t.b(si)  # Julia knows exactly which texture type this is
    return a_tex * t.percent_A + (1.0 - t.percent_A) * b_tex
end

@inline function (t::MixBlendTexture{Spectrum, A, B})(si::SurfaceInteraction)::Spectrum where {A, B}
    a_tex = t.a(si)  # Julia knows exactly which texture type this is
    b_tex = t.b(si)  # Julia knows exactly which texture type this is
    return a_tex .* t.percent_A + (1.0 - t.percent_A) .* b_tex
end
################################
######### Draw a Circle using UV
################################
struct CircleProceduralTexture{T <: Union{Float64, Spectrum}} <: AbstractTexture{T}
    # these are to be specified in UV so [0,1]
    center::Pnt2
    radius::Float64
    inside::T
    outside::T
    name::Maybe{String}
    mapping::AbstractTextureMapping2D

    function CircleProceduralTexture(
        center::Pnt2, 
        radius::Float64, 
        inside::T, 
        outside::T, 
        name::Maybe{String}=nothing,
        mapping::AbstractTextureMapping2D=UVMapping2D()
    )::CircleProceduralTexture{T} where T <: Union{Float64, Spectrum}
        return new{T}(center, radius, inside, outside, name, mapping)
    end
end

function (cpt::CircleProceduralTexture{T})(si::SurfaceInteraction)::T where T <: Union{Float64, Spectrum}
    st, dstdx, dstdy = cpt.mapping(si)
    u, v = st
    if (u-cpt.center[1])^2 + (v-cpt.center[2])^2 <= cpt.radius^2
        return cpt.inside
    else
        return cpt.outside
    end
end

################################
######### Draw a Circle using UV
################################
struct RectangleProceduralTexture{T <: Union{Float64, Spectrum}} <: AbstractTexture{T}
    # these are to be specified in UV so [0,1]
    p_min::Pnt2
    p_max::Pnt2
    inside::T
    outside::T
    name::Maybe{String}
    mapping::AbstractTextureMapping2D

    function RectangleProceduralTexture(
        p_min::Pnt2, 
        p_max::Pnt2, 
        inside::T, 
        outside::T, 
        name::Maybe{String}=nothing,
        mapping::AbstractTextureMapping2D=UVMapping2D()
    )::RectangleProceduralTexture{T} where T <: Union{Float64, Spectrum}
        @assert all(0.0 .<= p_min .<= 1.0)
        @assert all(0.0 .<= p_max .<= 1.0)
        @assert all(p_min .< p_max)
        return new{T}(p_min, p_max, inside, outside, name, mapping)
    end
end

function (rpt::RectangleProceduralTexture{T})(si::SurfaceInteraction)::T where T <: Union{Float64, Spectrum}
    st, dstdx, dstdy = rpt.mapping(si)
    u, v = st
    if (rpt.p_min.x <= u <= rpt.p_max.x) || (rpt.p_min.y <= v <= rpt.p_max.y)
        return cpt.inside
    else
        return cpt.outside
    end
end

################################
######### Select a Corner using UV
################################
struct CornerProceduralTexture{T <: Union{Float64, Spectrum}} <: AbstractTexture{T}
    threshold::Float64
    inside::T
    outside::T
    name::Maybe{String}
    mapping::AbstractTextureMapping2D

    function CornerProceduralTexture(
        threshold::Float64, 
        a::T, 
        b::T, 
        name::Maybe{String}=nothing,
        mapping::AbstractTextureMapping2D=UVMapping2D()
    )::CornerProceduralTexture{T} where T <: Union{Float64, Spectrum}
        return new{T}(threshold, a, b, name, mapping)
    end
end

function (cpt::CornerProceduralTexture{T})(si::SurfaceInteraction)::T where T <: Union{Float64, Spectrum}
    st, dstdx, dstdy = cpt.mapping(si)
    u, v = st
    if u+v < cpt.threshold
        return cpt.inside
    else
        return cpt.outside
    end
end

################################
######### Checkers
################################
struct Checker3DTexture{T <: Union{Float64, Spectrum}} <: AbstractTexture{T}
    a::T
    b::T
    scale::Pnt3
    name::Maybe{String}

    function Checker3DTexture(
        a::T, 
        b::T, 
        scale::Pnt3=Pnt3(1,1,1), 
        name::Maybe{String}=nothing
    )::Checker3DTexture{T} where T <: Union{Float64, Spectrum}
        return new{T}(a, b, scale, name)
    end
end

function (ct::Checker3DTexture{T})(si::SurfaceInteraction)::T where T <: Union{Float64, Spectrum}
    asdf = (trunc(ct.scale.x * si.core.p.x) + trunc(ct.scale.y * si.core.p.y) + trunc(ct.scale.z * si.core.p.z)) % 2 == 0
    if asdf == true
        return ct.a
    else
        return ct.b
    end
end
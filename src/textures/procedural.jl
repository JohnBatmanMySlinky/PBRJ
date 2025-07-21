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
end

function CircleProceduralTexture{T}(center::Pnt2, radius::Float64, inside::T, outside::T, name::Maybe{String}=nothing)::CircleProceduralTexture{T} where T <: Union{Float64, Spectrum}
    return CircleProceduralTexture{T}(center, radius, inside, outside, name)
end

function (cpt::CircleProceduralTexture{T})(si::SurfaceInteraction)::T where T <: Union{Float64, Spectrum}
    u, v = si.uv
    if (u-cpt.center[1])^2 + (v-cpt.center[2])^2 <= cpt.radius^2
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
end

function CornerProceduralTexture{T}(threshold::Float64, a::T, b::T, name::Maybe{String}=nothing)::CornerProceduralTexture{T} where T <: Union{Float64, Spectrum}
    return CornerProceduralTexture{T}(threshold, a, b, name)
end

function (cpt::CornerProceduralTexture{T})(si::SurfaceInteraction)::T where T <: Union{Float64, Spectrum}
    u, v = si.uv

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
end

function Checker3DTexture{T}(a::T, b::T, scale::Pnt3=Pnt3(1,1,1), name::Maybe{String}=nothing)::Checker3DTexture{T} where T <: Union{Float64, Spectrum}
    return Checker3DTexture{T}(a, b, scale, name)
end

function (ct::Checker3DTexture{T})(si::SurfaceInteraction)::T where T <: Union{Float64, Spectrum}
    asdf = (trunc(ct.scale.x * si.core.p.x) + trunc(ct.scale.y * si.core.p.y) + trunc(ct.scale.z * si.core.p.z)) % 2 == 0
    if asdf == true
        return ct.a
    else
        return ct.b
    end
end
################################
######### Draw a Circle using UV
################################
struct CircleProceduralTexture{T} where T <: Union{Float64, Spectrum}
    # these are to be specified in UV so [0,1]
    center::Pnt2
    radius::Float64
    inside::T
    outside::T
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
struct CornerProceduralTexture{T} where T <: Union{Float64, Spectrum}
    threshold::Float64
    inside::T
    outside::T
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
struct Checker3DTexture{T} where T <: Union{Float64, Spectrum}
    a::T
    b::T
    scale::Pnt3
end

function Checker3DTexture{T}(a::T, b::T)::Checker3DTexture{T} where T <: Union{Float64, Spectrum}
    return Checker3DTexture{T}(a, b, Pnt3(1,1,1))
end

function (ct::Checker3DTexture{T})(si::SurfaceInteraction)::T where T <: Union{Float64, Spectrum}
    asdf = (trunc(ct.scale.x * si.core.p.x) + trunc(ct.scale.y * si.core.p.y) + trunc(ct.scale.z * si.core.p.z)) % 2 == 0
    if asdf == true
        return ct.a
    else
        return ct.b
    end
end
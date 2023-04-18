################################
######### Draw a Circle using UV
################################
struct CircleProceduralTexture <: Texture
    # these are to be specified in UV so [0,1]
    center::Pnt2
    radius::Float64
    inside::Pnt3
    outside::Pnt3
end

function (cpt::CircleProceduralTexture)(si::SurfaceInteraction)::Spectrum
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
struct CornerProceduralTexture <: Texture
    threshold::Float64
    inside::Pnt3
    outside::Pnt3
end

function (cpt::CornerProceduralTexture)(si::SurfaceInteraction)::Spectrum
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
struct Checker3DTexture <: Texture
    a::Spectrum
    b::Spectrum
    scale::Pnt3
end

function Checker3DTexture(a::Spectrum, b::Spectrum)::CheckerTexture
    return Checker3DTexture(a,b,Pnt3(1,1,1))
end

function (ct::Checker3DTexture)(si::SurfaceInteraction)::Spectrum
    asdf = (trunc(ct.scale.x * si.core.p.x) + trunc(ct.scale.y * si.core.p.y) + trunc(ct.scale.z * si.core.p.z)) % 2 == 0
    if asdf == true
        return ct.a
    else
        return ct.b
    end
end
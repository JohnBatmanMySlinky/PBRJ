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

function (cpt::CircleProceduralTexture)(si::SurfaceInteraction)
    return cpt(si.uv)
end

function (cpt::CircleProceduralTexture)(uv::Pnt2)
    u, v = uv

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

function (cpt::CornerProceduralTexture)(si::SurfaceInteraction)
    return cpt(si.uv)
end

function (cpt::CornerProceduralTexture)(uv::Pnt2)
    u, v = uv

    if u+v < cpt.threshold
        return cpt.inside
    else
        return cpt.outside
    end
end
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

function (cpt::CornerProceduralTexture)(si::SurfaceInteraction)
    u, v = si.uv

    if u+v < cpt.threshold
        return cpt.inside
    else
        return cpt.outside
    end
end
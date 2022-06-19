struct Transformation
    m::Mat4
    inv_m::Mat4
end

function Inv(t::Transformation)::Transformation
    return Transformation(
        t.inv_m,
        t.m
    )
end

########################################
######## Generate Transformations ######
########################################

function Translate(v::Vec3)::Transformation
    m = Mat4([
        1 0 0 v[1]
        0 1 0 v[2]
        0 0 1 v[3]
        0 0 0 1
    ])
    m_inv = Mat4([
        1 0 0 -v[1]
        0 1 0 -v[2]
        0 0 1 -v[3]
        0 0 0 1
    ])
    return Transformation(m, m_inv)
end

########################################
### Apply Transformations to Things ####
########################################

# apply transformations to a vector
function (t::Transformation)(p::Vec3)::Vec3
    tmp = Vec4(p...,1)
    ph = Mat4([tmp tmp tmp tmp])
    pt = t.m * ph
    pr = Vec3(pt[1:3])
    if pt[4] == 1 
        return pr
    end
    return pr ./ pt[4]
end

# apply transformations to a ray
function (t::Transformation)(r::Ray)::Ray
    return Ray(
        t(r.origin),
        t(r.direction),
        r.time,
        r.tMax
    )
end

# apply transformations to a SurfaceInteraction
function (t::Transformation)(si::SurfaceInteraction)::SurfaceInteraction
    core = t(si.core)
    shading = t(si.shading)
    return SurfaceInteraction(
        core,
        shading,
        si.uv,
        t(si.dpdu),
        t(si.dpdv),
        t(si.dndu),
        t(si.dndv),
        si.shape,
        si.primitive
    )
end

# apply transformations to an Interaction
function (t::Transformation)(i::Interaction)::Interaction
    return Interaction(
        t(i.p),
        i.time,
        normalize(t(i.wo)),
        normalize(t(i.n)),
    )
end

# apply transformations to a ShadingInteraction
function (t::Transformation)(si::ShadingInteraction)::ShadingInteraction
    return ShadingInteraction(
        normalize(t(si.n)),
        t(si.dpdu),
        t(si.dpdv),
        t(si.dndu),
        t(si.dndv)
    )
end

# apply transformations to a bounding box
function (t::Transformation)(b::Bounds3)::Bounds3
    return Bounds3(
        t(b.pMin),
        t(b.pMax)
    )
end
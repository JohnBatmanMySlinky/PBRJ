struct Transformation
    m::Mat4
    inv_m::Mat4
end

# apply transformations to a vector
function (t::Transformation)(p::Vec3)::Vec3
    ph = Mat4(p..., 1f0)
    pt = t.m * ph
    pr = Vec3(pt[1:3])
    if pt[4] == 1 
        return pr
    end
    return pr ./ pt[4]
end

# apply transformations to a SurfaceInteraction
function (t::Transformation)(si::SurfaceInteraction)
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
        si.shape
    )
end
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

function Scale(v::Vec3)::Transformation
    m = Mat4([
        v[1] 0    0    0
        0    v[2] 0    0
        0    0    v[3] 0
        0    0    0    1
    ])

    m_inv = Mat4([
        1/v[1] 0      0      0
        0      1/v[2] 0      0
        0      0      1/v[3] 0
        0      0      0      1
    ])
    return Transformation(m, m_inv)
end

function Perspective(fov::Float64, near::Float64, far::Float64)::Transformation
    a = far / (far - near)
    b = -far * near / (far - near)
    p = transpose(Mat4([
        1 0 0 0
        0 1 0 0
        0 0 a b
        0 0 1 0
    ]))
    inv_tan = 1 / tan(deg2rad(fov) / 2)
    return Scale(Vec3(inv_tan, inv_tan, 1)) * Transformation(p, inv(p))
end

function LookAt(position::Vec3, target::Vec3, up::Vec3)
    z_axis = normalize(position - target)
    x_axis = normalize(cross(up, z_axis))
    y_axis = cross(z_axis, x_axis)

    m = transpose(Mat4(
        x_axis[1], y_axis[1], z_axis[1], 0,
        x_axis[2], y_axis[2], z_axis[2], 0,
        x_axis[3], y_axis[3], z_axis[3], 0,
        0, 0, 0, 1,
    ))
    out = Translate(position) * Transformation(m, transpose(m))
    #TODO
    #WHAT THE FUCK
    return Transformation(
        inv(transpose(out.m)),
        transpose(out.m),
    )
end

########################################
### Apply Transformations to Things ####
########################################

# mutliply two transformations

function Base.:*(t1::Transformation, t2::Transformation)
    return Transformation(t1.m * t2.m, t1.inv_m * t2.inv_m)
end

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
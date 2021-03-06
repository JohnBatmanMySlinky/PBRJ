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

function Translate(v::Union{Vec3,Pnt3})::Transformation
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

function LookAt(position::Pnt3, target::Pnt3, up::Vec3)
    z_axis = normalize(position - target)
    x_axis = normalize(cross(up, z_axis))
    y_axis = cross(z_axis, x_axis)

    m = transpose(Mat4(
        x_axis[1], y_axis[1], z_axis[1], 0,
        x_axis[2], y_axis[2], z_axis[2], 0,
        x_axis[3], y_axis[3], z_axis[3], 0,
        0, 0, 0, 1,
    ))
    return Translate(position) * Transformation(m, inv(m))
end

########################################
### Apply Transformations to Things ####
########################################

# mutliply two transformations
function Base.:*(t1::Transformation, t2::Transformation)
    return Transformation(t1.m * t2.m, t1.inv_m * t2.inv_m)
end

# PBR 2.8.1
# apply transformations to a POINT
function (t::Transformation)(p::Pnt3)::Pnt3
    tmp = Pnt4(p...,1)
    ph = Mat4([tmp tmp tmp tmp])
    pt = t.m * ph
    pr = Pnt3(pt[1:3])
    if pt[4] == 1 
        return pr
    end
    return pr ./ pt[4]
end

# PBR 2.8.2
# apply transformations to a VECTOR
function (t::Transformation)(v::Vec3)::Vec3
    return t.m[1:3, 1:3] * v
end

# PBR 2.8.3
# apply transformations to a NORMAL
function (t::Transformation)(n::Nml3)::Nml3
    return transpose(t.inv_m[1:3, 1:3]) * n
end

# PBR 2.8.4
# apply transformations to a Ray
function (t::Transformation)(r::Ray)::Ray
    return Ray(
        t(r.origin),
        t(r.direction),
        r.time,
        r.tMax
    )
end

function (t::Transformation)(r::RayDifferential)::RayDifferential
    return RayDifferential(
        t(r.origin),
        t(r.direction),
        r.time,
        r.tMax,
        r.has_differentials,
        t(r.rx_origin),
        t(r.ry_origin),
        t(r.rx_direction),
        t(r.ry_direction)
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
        si.primitive,
        nothing,
        si.dudx,
        si.dudy,
        si.dvdx,
        si.dvdy,
        t(si.dpdx),
        t(si.dpdy),
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
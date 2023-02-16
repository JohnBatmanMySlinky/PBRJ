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

function RotateX(theta::Float64)::Transformation
    sin_theta = sin(deg2rad(theta))
    cos_theta = cos(deg2rad(theta))
    m = Mat4([
        1 0         0          0 
        0 cos_theta -sin_theta 0
        0 sin_theta cos_theta 0
        0 0         0          1
    ])
    return Transformation(m, inv(m))
end

function RotateY(theta::Float64)::Transformation
    sin_theta = sin(deg2rad(theta))
    cos_theta = cos(deg2rad(theta))
    m = Mat4([
        cos_theta  0 sin_theta 0
        0          1 0         0
        -sin_theta 0 cos_theta 0
        0          0 0         1
    ])
    return Transformation(m, inv(m))
end

function RotateZ(theta::Float64)::Transformation
    sin_theta = sin(deg2rad(theta))
    cos_theta = cos(deg2rad(theta))
    m = Mat4([
        cos_theta -sin_theta 0 0
        sin_theta cos_theta  0 0
        0         0          1 0
        0         0          0 1
    ])
    return Transformation(m, inv(m))
end


function Perspective(fov::Float64, near::Float64, far::Float64)::Transformation
    a = far / (far - near)
    b = -far * near / (far - near)
    p = Mat4([
        1 0 0 0
        0 1 0 0
        0 0 a b
        0 0 1 0
    ])
    inv_tan = 1 / tan(deg2rad(fov) / 2)
    return Scale(Vec3(inv_tan, inv_tan, 1)) * Transformation(p, inv(p))
end

function LookAt(pos::Pnt3, look::Pnt3, up::Vec3)::Transformation
    dir = normalize(look - pos)
    left = normalize(cross(normalize(up), dir))
    new_up = cross(dir, left)
    m = Mat4([
        left.x new_up.x dir.x pos.x
        left.y new_up.y dir.y pos.y
        left.z new_up.z dir.z pos.z
        0      0        0     1
    ])
    return Transformation(m, inv(m))
end

########################################
### Apply Transformations to Things ####
########################################

# mutliply two transformations
function Base.:*(t1::Transformation, t2::Transformation)::Transformation
    return Transformation(t1.m * t2.m, t2.inv_m * t1.inv_m)
end

# PBR 2.8.1
# apply transformations to a POINT
function (t::Transformation)(p::Pnt3)::Pnt3
    tmp = Pnt4(p...,1.0)
    ph = Mat4([tmp tmp tmp tmp])
    pt = t.m * ph
    pr = Pnt3(pt[SA[1,2,3]])
    if pt[4] == 1.0
        return pr
    end
    return pr ./ pt[4]
end

# PBR 2.8.2
# apply transformations to a VECTOR
function (t::Transformation)(v::Vec3)::Vec3
    return t.m[SA[1,2,3], SA[1,2,3]] * v
end

# PBR 2.8.3
# apply transformations to a NORMAL
function (t::Transformation)(n::Nml3)::Nml3
    return transpose(t.inv_m[SA[1,2,3], SA[1,2,3]]) * n
end

# PBR 2.8.4
# apply transformations to a Ray
function (t::Transformation)(r::Ray)::Ray
    return Ray(
        t(r.origin),
        t(r.direction),
        r.t,
        r.tMax
    )
end

function (t::Transformation)(r::RayDifferential)::RayDifferential
    return RayDifferential(
        t(r.origin),
        t(r.direction),
        r.t,
        r.tMax,
        r.has_differentials,
        t(r.rx_origin),
        t(r.ry_origin),
        t(r.rx_direction),
        t(r.ry_direction)
    )
end

# PBR 2.8.5
# apply transformations to a Bounding Box
function (t::Transformation)(b::Bounds3)
    ret = Bounds3(t(Pnt3(b.pMin.x, b.pMin.y, b.pMin.z)))
    ret = world_bounds(ret, Bounds3(t(Pnt3(b.pMax.x, b.pMin.y, b.pMin.z))))
    ret = world_bounds(ret, Bounds3(t(Pnt3(b.pMin.x, b.pMax.y, b.pMin.z))))
    ret = world_bounds(ret, Bounds3(t(Pnt3(b.pMin.x, b.pMin.y, b.pMax.z))))
    ret = world_bounds(ret, Bounds3(t(Pnt3(b.pMin.x, b.pMax.y, b.pMax.z))))
    ret = world_bounds(ret, Bounds3(t(Pnt3(b.pMax.x, b.pMax.y, b.pMin.z))))
    ret = world_bounds(ret, Bounds3(t(Pnt3(b.pMax.x, b.pMin.y, b.pMax.z))))
    ret = world_bounds(ret, Bounds3(t(Pnt3(b.pMax.x, b.pMax.y, b.pMax.z))))
    return ret
end
# function (t::Transformation)(b::Bounds3)
#     mapreduce(i -> corner(b, i) |> t |> Bounds3, world_bounds, 1:8)
# end

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
        i.t,
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
struct UVMapping2D <: AbstractTextureMapping2D
    su::Float64
    sv::Float64
    du::Float64
    dv::Float64
end

function UVMapping2D()::UVMapping2D
    return UVMapping2D(1.0, 1.0, 0.0, 0.0)
end

function (m::UVMapping2D)(si::SurfaceInteraction)::Tuple{Pnt2, Vec2, Vec2}
    dstdx = Vec2(m.su * si.dudx, m.sv * si.dvdx)
    dstdy = Vec2(m.su * si.dudy, m.sv * si.dvdy)
    p = Pnt2(m.su * si.uv.x + m.du, m.sv * si.uv.y + m.dv)
    return p, dstdx, dstdy
end

struct UVMapping2DFull <: AbstractTextureMapping2D
    # 2x2 transformation matrix elements
    m11::Float64  # u coefficient for new u
    m12::Float64  # v coefficient for new u
    m21::Float64  # u coefficient for new v
    m22::Float64  # v coefficient for new v
    # Translation vector
    du::Float64   # u offset
    dv::Float64   # v offset
end

function UVMapping2DFull()::UVMapping2DFull
    return UVMapping2DFull(1.0, 0.0, 0.0, 1.0, 0.0, 0.0)
end

function (m::UVMapping2DFull)(si::SurfaceInteraction)::Tuple{Pnt2, Vec2, Vec2}
    # Transform the UV coordinates: [u', v'] = M * [u, v] + [du, dv]
    u_new = m.m11 * si.uv.x + m.m12 * si.uv.y + m.du
    v_new = m.m21 * si.uv.x + m.m22 * si.uv.y + m.dv
    p = Pnt2(u_new, v_new)
    
    # Transform the partial derivatives
    # dstdx = M * [dudx, dvdx]
    dstdx = Vec2(m.m11 * si.dudx + m.m12 * si.dvdx,
                 m.m21 * si.dudx + m.m22 * si.dvdx)
    
    # dstdy = M * [dudy, dvdy] 
    dstdy = Vec2(m.m11 * si.dudy + m.m12 * si.dvdy,
                 m.m21 * si.dudy + m.m22 * si.dvdy)
    
    return p, dstdx, dstdy
end

function UVMapping2DFull_rotate_90_cw()::UVMapping2DFull
    return UVMapping2DFull(
        0.0,  1.0,  # m11, m12: new_u = 0*u + 1*v = v
        -1.0, 0.0,  # m21, m22: new_v = -1*u + 0*v = -u
        1.0,  0.0   # du, dv: translate by (1,0) to keep in [0,1]
    )
end

# 90 degrees counterclockwise rotation  
function UVMapping2DFull_rotate_90_ccw()::UVMapping2DFull
    return UVMapping2DFull(
        0.0, -1.0,  # m11, m12: new_u = 0*u + (-1)*v = -v
        1.0,  0.0,  # m21, m22: new_v = 1*u + 0*v = u
        0.0,  1.0   # du, dv: translate by (0,1) to keep in [0,1]
    )
end
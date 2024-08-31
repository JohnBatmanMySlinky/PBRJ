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
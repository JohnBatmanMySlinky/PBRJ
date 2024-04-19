struct UVMapping2D <: AbstractTextureMapping2D
    su::Float64
    sv::Float64
    du::Float64
    dv::Float64
   
    function UVMapping2D()
        return new(1.0, 1.0, 0.0, 0.0)
    end
end

function map(mapper::UVMapping2D, si::SurfaceInteraction)::Tuple{Pnt2, Vec2, Vec2}
    dstdx = Vec2(mapper.su * si.dudx, mapper.sv * si.dvdx)
    dstdy = Vec2(mapper.su * si.dudy, mapper.sv * si.dvdy)
    return Pnt2(mapper.su * si.uv[0] + du, mapper.sv * si.uv.y + dv), dstdx, dstdy
end
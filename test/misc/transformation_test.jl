"""
TLDR; If you index a SA with a UnitRange you get an Array, if you index a SA with a SA you get a SA
"""


include("../src/RayTracing.jl")

using JET

function build()::Tuple{RayTracing.Pnt3, RayTracing.Transformation}
    p = RayTracing.Pnt3(1.0, 2.0, 3.0)
    t = RayTracing.Translate(RayTracing.Pnt3(2.0, 2.0, 2.0))
    return p,t
end


function a(p::RayTracing.Pnt3, t::RayTracing.Transformation, N::Int64)
    for n in 1:N
        t(p)
    end
end


function b(p::RayTracing.Pnt3, t::RayTracing.Transformation, N::Int64)
    for n in 1:N
        apply(t,p)
    end
end

function c(p::RayTracing.Pnt3, t::RayTracing.Transformation, N::Int64)
    for n in 1:N
        apply2(t,p)
    end
end

function d(p::RayTracing.Pnt3, t::RayTracing.Transformation, N::Int64)
    for n in 1:N
        apply3(t,p)
    end
end

function apply(t::RayTracing.Transformation, p::RayTracing.Pnt3)::RayTracing.Pnt3
    xp = t.m[1]*p.x + t.m[2]*p.y + t.m[3]*p.z + t.m[4]
    yp = t.m[5]*p.x + t.m[6]*p.y + t.m[7]*p.z + t.m[8]
    zp = t.m[9]*p.x + t.m[10]*p.y + t.m[11]*p.z + t.m[12]
    wp = t.m[13]*p.x + t.m[14]*p.y + t.m[15]*p.z + t.m[16]
    if wp == 1.0
        return RayTracing.Pnt3(xp, yp, zp)
    else
        return RayTracing.Pnt3(xp, yp, zp) ./ wp
    end
end

function apply2(t::RayTracing.Transformation, p::RayTracing.Pnt3)::RayTracing.Pnt3
    tmp = RayTracing.Pnt4(p...,1.0)
    ph = RayTracing.Mat4([tmp tmp tmp tmp])
    pt = t.m * ph
    pr = RayTracing.Pnt3(pt[1:3])
    if pt[4] == 1.0 
        return pr
    end
    return pr ./ pt[4]
end

function apply3(t::RayTracing.Transformation, p::RayTracing.Pnt3)::RayTracing.Pnt3
    tmp = RayTracing.Pnt4(p...,1.0)
    ph = RayTracing.Mat4([tmp tmp tmp tmp])
    pt = t.m * ph
    pr = RayTracing.Pnt3(pt[RayTracing.SA[1,2,3]])
    if pt[4] == 1.0 
        return pr
    end
    return pr ./ pt[4]
end


function yeehaw()
    p,t = build()
    a(p,t,1_000_000)
    b(p,t,1_000_000)
    c(p,t,1_000_000)
    d(p,t,1_000_000)
    @time a(p,t,1_000_000)
    @time b(p,t,1_000_000)
    @time c(p,t,1_000_000)
    @time d(p,t,1_000_000)
end


yeehaw()
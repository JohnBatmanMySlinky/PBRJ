struct ONB
    u::Vec3
    v::Vec3
    w::Vec3
end

function build_from_w(n::Vec3)::ONB
    w = unit_vector(n)
    if abs(w[1]) > 0.9
        a = Vec3(0,1,0)
    else
        a = Vec3(1,0,0)
    end
    v = unit_vector(cross(w,a))
    u = cross(w,v)
    return ONB(u,v,w)
end

function localize(onb::ONB, v::Vec3)::Vec3
    return (onb.u .* v[1]) .+ (onb.v .* v[2]) .+ (onb.w .* v[3])
end
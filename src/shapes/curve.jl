struct CurveCommon
    type::String
    cp_obj::SVector{4, Pnt3} 
    width::Pnt2
    n::Maybe{SVector{2, Nml3}}
    normal_angle::Maybe{Float64}
    inv_sin_normal_angle::Maybe{Float64}
    core::ShapeCore

    function CurveCommon(
        type::String,
        cp_obj::SVector{4, Pnt3},
        width0::Maybe{Float64},
        width1::Maybe{Float64},
        n::Maybe{SVector{2, Nml3}},
        core::ShapeCore
    )
        if !(n isa Nothing)
            normal_angle = angle_between(n[0+1], n[1+1])
            inv_sin_normal_angle = 1.0 / sin(normal_angle)
            return new(
                type,
                cp_obj,
                Pnt2(width0, width1),
                n,
                normal_angle,
                inv_sin_normal_angle,
                core
            )
        else
            return new(
                type,
                cp_obj,
                Pnt2(width0, width1),
                n,
                nothing,
                nothing,
                core
            )
        end
    end
end

struct Curve <: Shape
    common::CurveCommon
    u_min::Float64
    u_max::Float64
end

function CreateCurve(
    core::ShapeCore, c::SVector{4, Pnt3}, w0::Float64, w1::Float64, 
    type::String, n::Maybe{SVector{2, Nml3}}, split_depth::Int64
)::Array{Curve}
    common = CurveCommon(type, c, w0, w1, n, core)
    n_segments = 1 << split_depth
    segments = Curve[]
    for i in 0:(n_segments-1)
        u_min::Float64 = i / n_segments
        u_max::Float64 = (i+1) / n_segments
        push!(segments, Curve(common, u_min, u_max))
    end
    return segments
end
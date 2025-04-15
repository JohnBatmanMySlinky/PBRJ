using StaticArrays, BenchmarkTools

const Pnt3 = SVector{3, Float64}
const Pnt4 = SVector{4, Float64}

const Mat4 = SMatrix{4, 4, Float64, 16}

struct Transformation
    m::Mat4
    inv_m::Mat4
end

function Translate(v::Pnt3)::Transformation
    m = Mat4(
        1, 0, 0, v[1],
        0, 1, 0, v[2],
        0, 0, 1, v[3],
        0, 0, 0, 1,
    )
    m_inv = Mat4(
        1, 0, 0, -v[1],
        0, 1, 0, -v[2],
        0, 0, 1, -v[3],
        0, 0, 0, 1,
    )
    return Transformation(m, m_inv)
end

function (t::Transformation)(p::Pnt3)::Pnt3
    tmp = Pnt4(p...,1.0)
    ph = Mat4(tmp..., tmp..., tmp..., tmp...)
    pt = t.m * ph
    pr = Pnt3(pt[SA[1,2,3]])
    if pt[4] == 1.0
        return pr
    end
    return pr ./ pt[4]
end

const p = Pnt3(1,2,3)
const tr = Translate(Pnt3(2,2,2))

function benchmark(tr::Transformation, p::Pnt3)::Pnt3
    @btime ($tr)($p)
end

benchmark(tr, p)
benchmark(tr, p)
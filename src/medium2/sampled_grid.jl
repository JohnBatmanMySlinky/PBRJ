struct SampledGrid
    values::Array{Float64}
    nx::Int64
    ny::Int64
    nz::Int64
end

function lookup(sg::SampledGrid, p::Pnt3)::Float64
    # compute voxel coordinates and offsets for _p_
    p_samples = Pnt3(
        p.x * sg.nx - 0.5,
        p.y * sg.ny - 0.5,
        p.z * sg.nz - 0.5,
    )
    p_i::Pnt3i = floor.(p_samples)
    d = p_samples - p_i
    
    # return trilinearly interpolated voxel values
    d00 = lerp(d.x, get(sg, p_i + Pnt3i(0, 0, 0)), get(sg, p_i + Pnt3i(1, 0, 0)))
    d10 = lerp(d.x, get(sg, p_i + Pnt3i(0, 1, 0)), get(sg, p_i + Pnt3i(1, 1, 0)))
    d01 = lerp(d.x, get(sg, p_i + Pnt3i(0, 0, 1)), get(sg, p_i + Pnt3i(1, 0, 1)))
    d11 = lerp(d.x, get(sg, p_i + Pnt3i(0, 1, 1)), get(sg, p_i + Pnt3i(1, 1, 1)))
    return lerp(d.z, lerp(d.y, d00, d10), lerp(d.y, d01, d11))
end

# WOW BE CAREFUL OF PBRT V4 LOOKUP WITH INTEGERS VS FLOAT!!!
function get(sg::SampledGrid, p::Pnt3i)::Float64
    sampled_bounds = Bounds3i(Pnt3i(0,0,0), Pnt3i(sg.nx, sg.ny, sg.nz))
    if !inside_exclusive(p, sampled_bounds)
        return 0.0
    else
        return sg.values[(p.z * sg.ny + p.y) * sg.nx + p.x + 1]
    end
end

function max_value(sg::SampledGrid, bounds::Bounds3)::Float64
    ps0 = Pnt3(bounds.pMin.x * sg.nx - 0.5, bounds.pMin.y * sg.ny - 0.5, bounds.pMin.z * sg.nz - 0.5)
    ps1 = Pnt3(bounds.pMax.x * sg.nx - 0.5, bounds.pMax.y * sg.ny - 0.5, bounds.pMax.z * sg.nz - 0.5)
    pi0::Pnt3i = max.(floor.(ps0), Pnt3i(0, 0, 0))
    pi1::Pnt3i = min.(floor.(ps1) + Pnt3i(1, 1, 1), Pnt3i(sg.nx - 1, sg.ny - 1, sg.nz - 1))

    max_value = get(sg, pi0)
    for z in pi0.z:pi1.z
        for y in pi0.y:pi1.y
            for x in pi0.x:pi1.x
                max_value = max(max_value, get(sg, Pnt3i(x,y,z)))
            end
        end
    end
    return max_value
end
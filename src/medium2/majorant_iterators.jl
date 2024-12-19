struct HomogeneousMajorantIterator <: AbstractMajorantIterator
    seg::RayMajorantSegment

    function HomogeneousMajorantIterator(t_min::Float64, t_max::Float64, sigma_as::Spectrum)
        return new(
            RayMajorantSegment(t_min, t_max, sigma_as),
        )
    end
end

function Base.iterate(hmi::HomogeneousMajorantIterator, i::Integer = 1,)::Union{Nothing, Tuple{RayMajorantSegment, Integer}}
    if i > 1
        return nothing
    end

    return hmi.seg, i + 1
end

struct MajorantGrid
    bounds::Bounds3
    voxels::Array{Float64}
    res::Pnt3
end

mutable struct DDAMajorantIterator <: AbstractMajorantIterator
    sigma_t::Spectrum
    t_min::Float64
    t_max::Float64
    grid::MajorantGrid
    next_crossing_T::FieldVector{3, Float64}
    delta_T::FieldVector{3, Float64}
    step::FieldVector{3, Int64}
    voxel_limit::FieldVector{3, Int64}
    voxel::FieldVector{3, Int64}

    function DDAMajorantIterator(
        ray::AbstractRay, 
        sigma_t::Spectrum, 
        grid::MajorantGrid,
        t_min::Float64=-typemax(Float64), 
        t_max::Float64=typemax(Float64)
    )
        diag = diagonal(grid.bounds)
        ray_grid = Ray(
            Pnt3(offset(grid.bounds, ray.origin)),
            Vec3(
                ray.direction.x / diag.x,
                ray.direction.y / diag.y,
                ray.direction.z / diag.z,
            ),
            0.0,
            typemax(Float64)
        )
        grid_intersect = at(ray_grid, t_min)
        for axis in 0:3
            voxel[axis+1] = clamp(grid_intersect[axis+1] * grid.res[axis+1], 0, grid.res[axis+1] - 1)
            delta_T[axis+1] = 1.0 / (abs(ray_grid.direction[axis+1]) * grid.res[axis+1])

            if ray_grid.direction[axis+1] >= 0
                next_voxel_pos = Float64(voxel[axis+1] + 1) / grid.res[axis+1]
                next_crossing_T[axis+1] = t_min + (next_voxel_pos - grid_intersect[axis+1]) / ray_grid.direction[axis+1]
                step[axis+1] = 1
                voxel_limit[axis+1] = grid.res[axis+1]
            else
                next_voxel_pos = Float64(voxel[axis+1]) / grid.res[axis+1]
                next_crossing_T[axis+1] = t_min + (next_voxel_pos - grid_intersect[axis+1]) / ray_grid.direction[axis+1]
                step[axis+1] = -1
                voxel_limit[axis+1] = -1
            end
        end

        return new(
            simga_t,
            t_min, t_max,
            grid,
            next_crossing_T, delta_T,
            step, voxel_limit, voxel
        )
    end
end

function lookup(ddami::DDAMajorantIterator, x::Int64, y::Int64, z::Int64)::Float64
    return ddami.voxels[x+ddami.grid.res.x * (y + ddami.grid.res.y * z) + 1]
end

function voxel_bounds(res::Pnt3, x::Int64, y::Int64, z::Int64)::Bounds3
    p0 = Pnt3(
        Float64(x) / res.x,
        Float64(y) / res.y,
        Float64(z) / res.z
    )
    p1 = Pnt3(
        Float64(x+1) / res.x,
        Float64(y+1) / res.y,
        Float64(z+1) / res.z
    )
    return Bounds3(p0, p1)
end

function Base.iterate(ddami::DDAMajorantIterator, i::Integer = 1,)::Union{Nothing, Tuple{RayMajorantSegment, Integer}}
    if ddami.t_min >= ddami.t_max
        return nothing
    end

    bits = ((ddami.next_crossing_T[0+1] < ddami.next_crossing_T[1+1]) << 2) + 
        ((ddami.next_crossing_T[0+1] < ddami.next_crossing_T[2+1]) << 1) + 
        (ddami.next_crossing_T[1+1] < ddami.next_crossing_T[2+1])
    cmp_to_axis = SVector(2, 1, 2, 1, 2, 2, 0, 0)
    step_axis = cmp_to_axis[bits]
    t_voxel_exit = min(ddami.t_max, ddami.next_crossing_T[step_axis+1])

    sigma_maj = sigma_t * lookup(ddami.grid, voxel[0+1], voxel[1+1], voxel[2+1])
    seg = RayMajorantSegment(ddami.t_min, t_voxel_exit, sigma_maj)

    ddami.t_min = t_voxel_exit
    if ddami.next_crossing_T[step_axis+1] > t_max
        ddami.t_min = ddami.t_max
    end
    voxel[step_axis+1] += step[step_axis+1]
    if voxel[step_axis+1] == voxel_limit[step_axis+1]
        ddami.t_min = ddami.t_max
    end
    next_crossing_T[step_axis+1] += delta_T[step_axis+1]

    return seg, i + 1
end
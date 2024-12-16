struct GridMedium <: AbstractMedium
    bounds::Bounds3
    render_from_medium::Transformation
    sigma_a::Spectrum
    sigma_s::Spectrum
    density_grid::SampledGrid
    phase::AbstractPhaseFunction
    # no temperature_grid right now
    Le::Spectrum
    Le_scale::SampledGrid
    # no is_emissive right now because no temp grid
    # no temperature_scale or temperature_offset either
    majorant_grid::MajorantGrid

    function GridMedium(
        nx::Int64,
        ny::Int64,
        nz::Int64,
        Le::Spectrum,
        sigma_a::Spectrum,
        sigma_s::Spectrum,
        sigma_scale::Float64=1.0,
        p0::Pnt3=Pnt3(0,0,0),
        p1::Pnt3=Pnt3(1,1,1),
        g::Float64=0.0,
        majorant_grid_res::Int64=16
    )
        density_grid = zeros(nx * ny * nz, Float64)
        majorant_grid = zeros(majorant_grid_res * majorant_grid_res * majorant_grid_res, Float64)
        for z in 0:majorant_grid.res.z
            for y in 0:majorant_grid.res.y
                for x in 0:majorant_grid.res.x
                    tmp_bounds = voxel_bounds(majorant_grid, x, y, z)
                    majorant_grid[x+majorant_grid.grid.res.x * (y + majorant_grid.grid.res.y * z) + 1] = max_value(density_grid, tmp_bounds)
                end
            end
        end
        return new(
            Bounds3(p0,p1),
            render_from_medium, 
            sigma_a * sigma_scale, 
            sigma_s * sigma_scale, 
            density_grid, 
            HenyeyGreenstein(g), 
            Le, 
            Le_scale, 
            majorant_grid
        )
    end
end


struct NanoVDBMedium <: AbstractMedium
    sigma_a::Spectrum
    sigma_s::Spectrum
    phase::AbstractPhaseFunction
    majorant_grid::MajorantGrid
    density_float_grid::NanoVDB.NanoVDBWrapperAllocated
    sigma_t::Float64
    bounds::Bounds3
    world_to_unit::Transformation

    function NanoVDBMedium(
        world_to_medium::Transformation,
        sigma_a::Spectrum,
        sigma_s::Spectrum, 
        g::Float64, 
        scale::Float64,
        fpath::String,
        majorant_grid_res::Pnt3
    )
        sigma_a *= scale
        sigma_s *= scale
        density_float_grid = NanoVDB.make_NanoVDBWrapper(fpath)
        a, b, c, d, e, f = NanoVDB.get_WorldBBox(density_float_grid)

        bounds = Bounds3(Pnt3(a, b, c), Pnt3(d, e, f))
        @info "World Medium Bounds: $(b)"
        medium_to_unit = UnitCube(b)

        majorant_grid_size = majorant_grid_res.x * majorant_grid_res.y * majorant_grid_res.z
        majorant_grid_d = zeros(Float64, majorant_grid_size)
        for index in 0:(majorant_grid_size)
            # Indices into majorantGrid
            x = index % majorant_grid_res.x
            y = (index / majorant_grid_res.x) % majorant_grid_res.y
            z = index / (majorant_grid_res.x * majorant_grid_res.y);
            @assert index ==  x + majorant_grid_res.x * (y + majorant_grid_res.y * z)

            # World (aka medium) space bounds of this max grid cell
            wb = Bounds3(
                lerp(bounds, Pnt3(
                    x/majorant_grid_res.x,
                    y/majorant_grid_res.y,
                    z/majorant_grid_res.z,
                )),
                lerp(bounds, Pnt3(
                    (x+1)/majorant_grid_res.x,
                    (y+1)/majorant_grid_res.y,
                    (z+1)/majorant_grid_res.z,
                ))
            )

            # Compute corresponding NanoVDB index-space bounds in floating-point.
            i0x, i0y, i0z = NanoVDB.get_worldToIndexF(density_float_grid, wb.pMin.x, wb.pMin.y, wb.pMin.z)
            i1x, i1y, i1z = NanoVDB.get_worldToIndexF(density_float_grid, wb.pMax.x, wb.pMax.y, wb.pMax.z)

            # Now find integer index-space bounds, accounting for both filtering and the overall index bounding box.
            a, b, c, d, e, f = bbox = NanoVDB.get_indexBBox(density_float_grid)
            delta = 1.0  # Filter slop
            nx0 = max(int(i0x - delta), bbox.min()[0+1])
            nx1 = min(int(i1x + delta), bbox.max()[0+1])
            ny0 = max(int(i0y - delta), bbox.min()[1+1])
            ny1 = min(int(i1y + delta), bbox.max()[1+1])
            nz0 = max(int(i0z - delta), bbox.min()[2+1])
            nz1 = min(int(i1z + delta), bbox.max()[2+1])

            max_value = NanoVDB.get_max_value_voxel(density_float_grid, nx0, nx1, ny0, ny1, nz0, nz1)
            
            majorant_grid_d[index] = max_value
        end

        return new(
            sigma_a, sigma_s, 
            HenyeyGreenstein(g), 
            MajorantGrid(bounds, majorant_grid_d, majorant_grid_res),
            density_float_grid, 
            y_spectrum(sigma_a + sigma_s), 
            bounds, 
            world_to_medium * medium_to_unit
        )
    end
end
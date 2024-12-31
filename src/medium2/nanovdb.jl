struct NanoVDBMedium <: AbstractMedium
    sigma_a::Spectrum
    sigma_s::Spectrum
    phase::AbstractPhaseFunction
    majorant_grid::MajorantGrid
    density_float_grid::NanoVDB.NanoVDBWrapperAllocated
    sigma_t::Float64
    bounds::Bounds3
    render_from_medium::Transformation

    function NanoVDBMedium(
        render_from_medium::Transformation,
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

        println("CONSTRUCTOR: renderFromMedium $render_from_medium") 

        bounds = Bounds3(Pnt3(a, b, c), Pnt3(d, e, f))
        @info "World Medium Bounds: $(b)"
        # medium_to_unit = UnitCube(b)
        println("Coonstructor BOUNDS: $bounds")

        majorant_grid_size = majorant_grid_res.x * majorant_grid_res.y * majorant_grid_res.z
        majorant_grid_d = zeros(Float64, Int64(majorant_grid_size))
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
            println("Coonstructor WB: $wb")

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
            println("MAJORANT GRID: $x $y $z $max_value")
            
            majorant_grid_d[index] = max_value
        end

        @assert false
        return new(
            sigma_a, sigma_s, 
            HenyeyGreenstein(g), 
            MajorantGrid(bounds, majorant_grid_d, majorant_grid_res),
            density_float_grid, 
            y_spectrum(sigma_a + sigma_s), 
            bounds, 
            render_from_medium
        )
    end
end

function sample_point(nvdbm::NanoVDBMedium, p::Pnt3)::MediumProperties
    # Scale scattering coefficients by medium density at _p_
    p = nvdbm.render_from_medium(p)
    p = offset(nvdbm.bounds, p)
    d = lookup(nvdbm.density_grid, p)
    sigma_a = nvdbm.sigma_a * d
    sigma_s = nvdbm.sigma_s * d

    # Compute grid emission _Le_ at _p_
    Le = spectrum_from_float(0.0)
    # NOT EMISSIVE SO SKIP

    return MediumProperties(sigma_a, sigma_s, gm.phase, Le)
end

function sample_ray(nvdbm::NanoVDBMedium, ray::AbstractRay, ray_t_max::Float64)::Maybe{AbstractMajorantIterator}
    # Transform ray to medium's space and compute bounds overlap
    # JOHN HACK: WHAT IS ray_t_max DOING HERE???
    ray = nvdbm.render_from_medium(ray)
    # println("SAMPLE RAY: RAY: $ray")
    # println("SAMPLE RAY: BOUNDS: $(gm.bounds)")
    check, t_min, t_max = intersect_p(nvdbm.bounds, ray, ray_t_max)
    if !check
        return nothing
    end

    return DDAMajorantIterator(ray, nvdbm.sigma_a + nvdbm.sigma_s, nvdbm.majorant_grid, t_min, t_max)
end

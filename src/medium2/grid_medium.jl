struct GridMedium <: AbstractMedium
    bounds::Bounds3
    render_from_medium::Transformation
    sigma_a::Spectrum
    sigma_s::Spectrum
    sigma_scale::Float64
    phase::AbstractPhaseFunction
    density_grid::SampledGrid
    temperature_grid::Maybe{SampledGrid}
    le::Spectrum
    le_grid::Maybe{SampledGrid}
    is_emissive::Bool
    majorant_grid::MajorantGrid

    function GridMedium(
        fpath::String,
        medium_to_world::Transformation,
        sigma_a::Spectrum,
        sigma_s::Spectrum,
        sigma_scale::Float64=1.0,
        le::Spectrum,
        g::Float64=0.0,
        majorant_grid_res::Pnt3=Pnt3(16, 16, 16)
    )
        nx, ny, nz, d, le_grid, temperature_grid, p0, p1 = parse_media(fpath)
        density_grid = SampledGrid(d, nx, ny, nz)
        temperature_grid =  SampledGrid(temperature_grid, nx, ny, nz)
        le_grid = SampledGrid(d, nx, ny, nz)

        majorant_grid_d = zeros(Float64, Int64(majorant_grid_res.x * majorant_grid_res.y * majorant_grid_res.z))
        for z in 0:(majorant_grid_res.z-1)
            for y in 0:(majorant_grid_res.y-1)
                for x in 0:(majorant_grid_res.x-1)
                    tmp_bounds = voxel_bounds(majorant_grid_res, Int64(x), Int64(y), Int64(z))
                    majorant_grid_d[Int64(x+majorant_grid_res.x * (y + majorant_grid_res.y * z) + 1)] = max_value(density_grid, tmp_bounds)
                end
            end
        end
        majorant_grid = MajorantGrid(Bounds3(p0,p1), majorant_grid_d, majorant_grid_res)

        return new(
            Bounds3(p0,p1),
            Inv(medium_to_world), 
            sigma_a * sigma_scale, 
            sigma_s * sigma_scale, 
            sigma_scale,
            HenyeyGreenstein(g),
            density_grid, 
            temperature_grid,
            le,
            le_grid,
            !(temperature_grid isa Nothing) || !(le_grid isa Nothing),
            majorant_grid
        )
    end
end

function sample_point(gm::GridMedium, p::Pnt3)::MediumProperties
    # Scale scattering coefficients by medium density at _p_
    p = gm.render_from_medium(p)
    p = offset(gm.bounds, p)
    d = lookup(gm.density_grid, p)
    sigma_a = gm.sigma_a * d
    sigma_s = gm.sigma_s * d

    # Compute grid emission _Le_ at _p_
    Le = spectrum_from_float(0.0)
    # NOT EMISSIVE SO SKIP

    return MediumProperties(sigma_a, sigma_s, gm.phase, Le)
end

function sample_ray(gm::GridMedium, ray::AbstractRay, ray_t_max::Float64)::Maybe{AbstractMajorantIterator}
    # Transform ray to medium's space and compute bounds overlap
    # JOHN HACK: WHAT IS ray_t_max DOING HERE???
    ray = gm.render_from_medium(ray)
    # println("SAMPLE RAY: RAY: $ray")
    # println("SAMPLE RAY: BOUNDS: $(gm.bounds)")
    check, t_min, t_max = intersect_p(gm.bounds, ray, ray_t_max)
    if !check
        return nothing
    end

    return DDAMajorantIterator(ray, gm.sigma_a + gm.sigma_s, gm.majorant_grid, t_min, t_max)
end

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
        sigma_scale::Float64,
        le::Spectrum,
        le_grid_scale::Float64=1.0,
        g::Float64=0.0,
        majorant_grid_res::Pnt3i=Pnt3i(16, 16, 16)
    )
        parsed_media = parse_media(fpath)
        density_grid = SampledGrid(parsed_media.density, parsed_media.nx, parsed_media.ny, parsed_media.nz)
        if !(parsed_media.temperature_grid isa Nothing)
            temperature_grid =  SampledGrid(parsed_media.temperature_grid, parsed_media.nx, parsed_media.ny, parsed_media.nz)
        end
        if !(parsed_media.le_grid isa Nothing)
            le_grid = SampledGrid(parsed_media.le_grid * le_grid_scale, parsed_media.nx, parsed_media.ny, parsed_media.nz)
        end

        majorant_grid_d = zeros(Float64, majorant_grid_res.x * majorant_grid_res.y * majorant_grid_res.z)
        for z in 0:(majorant_grid_res.z-1)
            for y in 0:(majorant_grid_res.y-1)
                for x in 0:(majorant_grid_res.x-1)
                    tmp_bounds = voxel_bounds(majorant_grid_res, x, y, z)
                    majorant_grid_d[x+majorant_grid_res.x * (y + majorant_grid_res.y * z) + 1] = max_value(density_grid, tmp_bounds)
                end
            end
        end
        majorant_grid = MajorantGrid(Bounds3(parsed_media.p0, parsed_media.p1), majorant_grid_d, majorant_grid_res)

        return new(
            Bounds3(parsed_media.p0, parsed_media.p1),
            Inv(medium_to_world), 
            sigma_a * sigma_scale, 
            sigma_s * sigma_scale, 
            sigma_scale,
            HenyeyGreenstein(g),
            density_grid, 
            parsed_media.temperature_grid,
            le,
            le_grid,
            (!(parsed_media.temperature_grid isa Nothing)) || (maximum(le) > 0.0),
            majorant_grid
        )
    end
end

function is_emissive(gm::GridMedium)::Bool
    return gm.is_emissive
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
    if gm.is_emissive
        scale = lookup(gm.le_grid, p)
        if scale > 0.0
            # Compute emitted radiance using _temperatureGrid_ or _Le_spec_
            if !(gm.temperature_grid isa Nothing)
                @assert false
                temp = lookup(gm.temperature_grid, p)
                Le = scale * black_body_spectrum(temp)
            else
                Le = scale * gm.le
            end
        end
    end

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

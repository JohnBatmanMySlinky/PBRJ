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

        # println("CONSTRUCTOR: renderFromMedium $render_from_medium") 

        bounds = Bounds3(Pnt3(a, b, c), Pnt3(d, e, f))
        @info "World Medium Bounds: $(bounds)"
        # println("Coonstructor BOUNDS: $bounds")

        # moving this outside the loop
        # a, b, c, d, e, f = bbox = NanoVDB.get_indexBBox(density_float_grid)
        # bbox = Bounds3(Pnt3(a,b,c), Pnt3(d,e,f))
        # println("BBox: $bbox")

        # println("Starting MajorantGridBuild")
        majorant_grid_d = NanoVDB.build_majorant_grid(
            density_float_grid,
            Int64(majorant_grid_res.x), 
            Int64(majorant_grid_res.y), 
            Int64(majorant_grid_res.z),
        )

        majorant_grid_size = Int64(majorant_grid_res.x * majorant_grid_res.y * majorant_grid_res.z)

        @assert length(majorant_grid_d) == majorant_grid_size

        # for index in 0:(majorant_grid_size-1)
        #     x::Int64 = trunc(index % majorant_grid_res.x)
        #     y::Int64 = trunc((index / majorant_grid_res.x) % majorant_grid_res.y)
        #     z::Int64 = trunc(index / (majorant_grid_res.x * majorant_grid_res.y))

        #     println("MajorantGridDensities: $x, $y, $z = $(majorant_grid_d[index+1])")
        # end

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

    d = NanoVDB.get_sampled_point(nvdbm.density_float_grid, p.x, p.y, p.z)
    
    # Compute grid emission _Le_ at _p_
    Le = spectrum_from_float(0.0)
    # NOT EMISSIVE SO SKIP

    return MediumProperties(nvdbm.sigma_a * d, nvdbm.sigma_s * d, nvdbm.phase, Le)
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

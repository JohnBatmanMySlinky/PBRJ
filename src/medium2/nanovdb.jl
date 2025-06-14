struct NanoVDBMedium <: AbstractMedium
    sigma_a::Spectrum
    sigma_s::Spectrum
    phase::AbstractPhaseFunction
    majorant_grid::MajorantGrid
    nanovdb_grid::NanoVDB.NanoVDBWrapperAllocated
    sigma_t::Float64
    bounds::Bounds3
    render_from_medium::Transformation
    Le_scale::Float64
    temperature_offset::Float64
    temperature_scale::Float64

    function NanoVDBMedium(
        render_from_medium::Transformation,
        sigma_a::Spectrum,
        sigma_s::Spectrum, 
        g::Float64, 
        scale::Float64,
        fpath::String,
        majorant_grid_res::Pnt3i,
        Le_scale::Float64=1.0,
        temperature_offset::Float64=0.0,
        temperature_scale::Float64=1.0
    )
        sigma_a *= scale
        sigma_s *= scale
        nanovdb_grid = NanoVDB.make_NanoVDBWrapper(fpath)
        a, b, c, d, e, f = NanoVDB.get_WorldBBox(nanovdb_grid)

        # println("CONSTRUCTOR: renderFromMedium $render_from_medium") 

        bounds = Bounds3(Pnt3(a, b, c), Pnt3(d, e, f))
        @info "World Medium Bounds: $(bounds)"
        # println("Coonstructor BOUNDS: $bounds")

        # println("Starting MajorantGridBuild")
        majorant_grid_d = NanoVDB.build_majorant_grid(
            nanovdb_grid,
            majorant_grid_res.x, 
            majorant_grid_res.y, 
            majorant_grid_res.z,
        )

        majorant_grid_size = majorant_grid_res.x * majorant_grid_res.y * majorant_grid_res.z

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
            nanovdb_grid, 
            y_spectrum(sigma_a + sigma_s), 
            bounds, 
            render_from_medium,
            Le_scale,
            temperature_offset,
            temperature_scale
        )
    end
end

function sample_point(nvdbm::NanoVDBMedium, p::Pnt3)::MediumProperties
    # Scale scattering coefficients by medium density at _p_
    p = Inv(nvdbm.render_from_medium)(p)

    d = NanoVDB.get_sampled_point(nvdbm.nanovdb_grid, p.x, p.y, p.z)
    LL = le(nvdbm, p)

    return MediumProperties(nvdbm.sigma_a * d, nvdbm.sigma_s * d, nvdbm.phase, LL)
end

function sample_ray(nvdbm::NanoVDBMedium, ray::AbstractRay, ray_t_max::Float64)::Maybe{AbstractMajorantIterator}
    # Transform ray to medium's space and compute bounds overlap
    # JOHN HACK: WHAT IS ray_t_max DOING HERE???
    ray = Inv(nvdbm.render_from_medium)(ray)
    # println("SAMPLE RAY: RAY: $ray")
    # println("SAMPLE RAY: BOUNDS: $(gm.bounds)")
    check, t_min, t_max = intersect_p(nvdbm.bounds, ray, ray_t_max)
    if !check
        return nothing
    end

    return DDAMajorantIterator(ray, nvdbm.sigma_a + nvdbm.sigma_s, nvdbm.majorant_grid, t_min, t_max)
end

function le(nvdbm::NanoVDBMedium, p::Pnt3)::Spectrum
    temp = NanoVDB.get_sampled_temperature(nvdbm.nanovdb_grid, p.x, p.y, p.z)        
    temp = (temp - nvdbm.temperature_offset) * nvdbm.temperature_scale
    if (temp <= 100.0)
        return spectrum_from_float(0.0)
    else
        return nvdbm.Le_scale * spectrum_from_sampled(CIE_lambda, blackbody(CIE_lambda, temp), length(CIE_lambda))
    end
end

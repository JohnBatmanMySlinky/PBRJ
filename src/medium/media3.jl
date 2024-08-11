struct NanoVDBMedium <: AbstractMedium
    sigma_a::Spectrum
    sigma_s::Spectrum
    g::Float64
    density_float_grid::NanoVDB.NanoVDBWrapperAllocated
    sigma_t::Float64
    inv_max_density::Float64
    bounds::Bounds3
    medium_to_unit::Transformation

    function NanoVDBMedium(
        sigma_a::Spectrum,
        sigma_s::Spectrum, 
        g::Float64, 
        scale::Float64,
        fpath::String
    )
        sigma_a *= scale
        sigma_s *= scale
        density_float_grid = NanoVDB.make_NanoVDBWrapper(fpath)
        a, b, c, d, e, f = NanoVDB.get_WorldBBox(density_float_grid)
        print("youll never see this\n")
        _, max_density = NanoVDB.get_extrema(density_float_grid)

        b = Bounds3(Pnt3(a, b, c), Pnt3(d, e, f))
        @info "World Medium Bounds: $(b)"
        medium_to_unit = UnitCube(b)

        return new(
            sigma_a, sigma_s, g, 
            density_float_grid, (sigma_a + sigma_s)[0+1], 
            1.0 / max_density, b, medium_to_unit
        )
    end
end
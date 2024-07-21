struct NanoVDBMedium <: AbstractMedium
    sigma_a::Spectrum
    sigma_s::Spectrum
    g::Float64
    world_to_medium::Transformation
    density_float_grid::NanoVDB.NanoVDBWrapperAllocated
    sigma_t::Float64
    inv_max_density::Float64
    bounds::Bounds3
    medium_to_unit::Transformation

    function NanoVDBMedium(sigma_a::Spectrum, sigma_s::Spectrum, 
        g::Float64, p0::Pnt3, p1::Pnt3, medium_to_world::Transformation, fpath::String
    )
        data_to_medium = Translate(Vec3(p0)) * Scale(p1.x - p0.x, p1.y - p0.y, p1.z - p0.z)
        tmp = Inv(medium_to_world * data_to_medium)
        @info "WTF IS THIS TRANSFORM: $(tmp)"

        density_float_grid = NanoVDB.make_NanoVDBWrapper(fpath)
        print("segfault time\n")
        a, b, c, d, e, f = NanoVDB.get_WorldBBox(density_float_grid)
        print("youll never see this\n")
        _, max_density = NanoVDB.get_extrema(density_float_grid)

        b = Bounds3(Pnt3(a, b, c), Pnt3(d, e, f))
        @info "World Medium Bounds: $(b)"
        medium_to_unit = UnitCube(b)

        return new(
            sigma_a, sigma_s, g, tmp, 
            density_float_grid, (sigma_a + sigma_s)[0+1], 
            1.0 / max_density, b, medium_to_unit
        )
    end
end
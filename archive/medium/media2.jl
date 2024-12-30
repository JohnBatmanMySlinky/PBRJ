struct GridDensityMedium <: AbstractMedium
    sigma_a::Spectrum
    sigma_s::Spectrum
    g::Float64
    nx::Int64
    ny::Int64
    nz::Int64
    world_to_medium::Transformation
    density::Vector{Float64}
    sigma_t::Float64
    inv_max_density::Float64
    
    # function GridDensityMedium(sigma_a::Spectrum, sigma_s::Spectrum, 
    #     g::Float64, p0::Pnt3, p1::Pnt3, nx::Int64, ny::Int64, nz::Int64, 
    #     medium_to_world::Transformation, d::Vector{Float64}
    # )
    #     return new(
    #         sigma_a, sigma_s, g, nx, ny, nz, Inv(medium_to_world), 
    #         d, (sigma_a + sigma_s)[0+1], 1.0 / maximum(d)
    #     )
    # end

    function GridDensityMedium(sigma_a::Spectrum, sigma_s::Spectrum, 
        g::Float64, p0::Pnt3, p1::Pnt3, medium_to_world::Transformation, fpath::String
    )
        data_to_medium = Translate(Vec3(p0)) * Scale(p1.x - p0.x, p1.y - p0.y, p1.z - p0.z)
        tmp = Inv(medium_to_world * data_to_medium)
        @info "WTF IS THIS TRANSFORM: $(tmp)"

        nx, ny, nz, d = parse_media(fpath)
        inv_max_density = 1.0 / maximum(d)
        @info "inv max density: $(inv_max_density)"

        return new(
            sigma_a, sigma_s, g, nx, ny, nz, tmp, 
            d, (sigma_a + sigma_s)[0+1], inv_max_density
        )
    end
end

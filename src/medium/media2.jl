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
    
    function GridDensityMedium(sigma_a::Spectrum, sigma_s::Spectrum, 
        g::Float64, nx::Int64, ny::Int64, nz::Int64, 
        medium_to_world::Transformation, d::Vector{Float64}
    )
        return new(
            sigma_a, sigma_s, g, nx, ny, nz, Inv(medium_to_world), 
            d, (sigma_a + sigma_s)[0+1], 1.0 / maximum(d)
        )
    end

    function GridDensityMedium(sigma_a::Spectrum, sigma_s::Spectrum, 
        g::Float64, medium_to_world::Transformation, fpath::String
    )
        nx, ny, nz, d = parse_media(fpath)
        return new(
            sigma_a, sigma_s, g, nx, ny, nz, Inv(medium_to_world), 
            d, (sigma_a + sigma_s)[0+1], 1.0 / maximum(d)
        )
    end
end

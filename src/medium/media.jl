struct HomogenousMedium <: AbstractMedium
    sigma_a::Spectrum
    sigma_s::Spectrum
    sigma_t::Spectrum
    g::Float64

    function HomogenousMedium(sigma_a::Spectrum, sigma_s::Spectrum)
        return new(sigma_a, sigma_s, sigma_a + sigma_s, 0.0)
    end
end

struct GridDensityMedium <: AbstractMedium
    sigma_a::Spectrum
    sigma_s::Spectrum
    g::Float64
    nx::Int64
    ny::Int64
    nz::Int64
    world_to_medium::Transformation
    density::Vector{Float64}
    sigma_t::Spectrum
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
end

struct MediumInterface
    inside::Maybe{AbstractMedium}
    outside::Maybe{AbstractMedium}
end

function MediumInterface(m::Maybe{AbstractMedium})
    return MediumInterface(m, m)
end
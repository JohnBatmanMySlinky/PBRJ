struct BSSRDFTable
    n_rho_samples::Int64
    n_radius_samples::Int64
    rho_samples::SVector{100, Float64}
    radius_samples::SVector{64, Float64}
    profile::SVector{100 * 64, Float64}
    rho_eff::SVector{100, Float64}
    profile_cdf::SVector{100 * 64, Float64}

    # equivalent to ComputeBeamDiffusionBSSRDF()
    function BSSRDFTable(g::Float64, eta::Float64)
        n_rho_samples = 100
        n_radius_samples = 64
        rho_samples = zeros(Float64, n_rho_samples)
        radius_samples = zeros(Float64, n_radius_samples)
        profile = zeros(Float64, n_rho_samples * n_radius_samples)
        rho_eff = zeros(Float64, n_rho_samples)
        profile_cdf = zeros(Float64, n_rho_samples * n_radius_samples)
        return new(n_rho_samples, n_radius_samples, rho_samples, radius_samples, profile, rho_eff, profile_cdf)
    end
end

function eval_profile(table::BSSRDFTable, rho_index::Int64, radius_index::Int64)::Float64
    return table.profile[rho_index * table.n_radius_samples + radius_index + 1]
end

function subsurface_from_diffuse(table::BSSRDFTable, rho_eff::Spectrum, mfp::Spectrum)::Tuple{Spectrum, Spectrum}
    sigma_a = zeros(Float64, nSpectralSamples)
    sigma_s = zeros(Float64, nSpectralSamples)
    for c in 0:(nSpectralSamples-1)
        rho = invert_catmull_rom(
            table.n_rho_samples, 
            table.rho_samples,
            table.rho_eff,
            rho_eff[c+1]
        )
        sigma_a[c + 1] = (1.0 - rho) / mfp[c + 1]
        sigma_s[c + 1] = rho / mfp[c + 1]
    end
    return Spectrum(sigma_a), Spectrum(sigma_s)
end
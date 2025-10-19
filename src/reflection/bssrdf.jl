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

        # Choose radius values of the diffusion profile discretization
        radius_samples[0 + 1] = 0
        radius_samples[1 + 1] = 2.5e-3
        for i in 2:(n_radius_samples - 1)
            radius_samples[i + 1] = radius_samples[i - 1 + 1] * 1.2
        end

        # Choose albedo values of the diffusion profile discretization
        for i in 0:(n_rho_samples - 1)
            rho_samples[i + 1] = (1.0 - exp(-8.0 * i / (n_rho_samples - 1))) / (1.0 - exp(-8.0))
            # Compute the diffusion profile for the _i_th albedo sample
            # Compute scattering profile for chosen albedo $\rho$
            for j in 0:(n_radius_samples - 1)
                rho = rho_samples[i + 1]
                r = radius_samples[j + 1]
                profile[i * n_radius_samples + j + 1] = 2 * pi * r * (
                    beam_diffusion_ss(rho, 1.0 - rho, g, eta, r) + 
                    beam_diffusion_ms(rho, 1.0 - rho, g, eta, r1)
                )
            end

            rho_eff[i + 1] = integrate_catmull_rom(
                n_radius_samples,
                radius_samples,
                profile[i * n_radius_samples + 1],
                profile_cdf[i * n_radius_samples + 1]
            )
        end
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
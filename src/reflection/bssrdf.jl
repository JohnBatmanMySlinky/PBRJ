struct BSSRDFTable
    n_rho_samples::Int64
    n_radius_samples::Int64
    rho_samples::SVector{5, Float64}
    radius_samples::SVector{2, Float64}
    profile::SVector{5 * 2, Float64}
    rho_eff::SVector{5, Float64}
    profile_cdf::SVector{5 * 2, Float64}

    # equivalent to ComputeBeamDiffusionBSSRDF()
    function BSSRDFTable(g::Float64, eta::Float64)
        n_rho_samples = 5
        n_radius_samples = 2
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

        for i in 0:(n_radius_samples-1)
            @info "BSSDRFTABLE::radiusSamples $i = $(radius_samples[i+1])"
        end

        # Choose albedo values of the diffusion profile discretization
        for i in 0:(n_rho_samples - 1)
            rho_samples[i + 1] = (1.0 - exp(-8.0 * i / (n_rho_samples - 1))) / (1.0 - exp(-8.0))
        end

        for i in 1:n_rho_samples
            @info "BSSDRFTABLE::rhoSamples $i = $(rho_samples[i])"
        end

        for i in 0:(n_rho_samples - 1)
            # Compute the diffusion profile for the _i_th albedo sample
            # Compute scattering profile for chosen albedo $\rho$
            for j in 0:(n_radius_samples - 1)
                rho = rho_samples[i + 1]
                r = radius_samples[j + 1]
                profile[i * n_radius_samples + j + 1] = 2 * pi * r * (
                    beam_diffusion_ss(rho, 1.0 - rho, g, eta, r) + 
                    beam_diffusion_ms(rho, 1.0 - rho, g, eta, r)
                )
            @info "BSSDRFTABLE::BeamDiffusionSS ($i, $j) = $(beam_diffusion_ss(rho, 1.0 - rho, g, eta, r))"
            @info "BSSDRFTABLE::BeamDiffusionMS ($i, $j) = $(beam_diffusion_ms(rho, 1.0 - rho, g, eta, r))"
            @info "BSSDRFTABLE::profile ($i, $j) = $(profile[i * n_radius_samples + j + 1])"
            end

            rho_eff[i + 1] = integrate_catmull_rom!(
                n_radius_samples,
                radius_samples,
                profile,
                profile_cdf,
                i * n_radius_samples
            )
            @info "BSSDRFTABLE::rhoEff $i = $(rho_eff[i + 1])"
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

function beam_diffusion_ms(sigma_s::Float64, sigma_a::Float64, g::Float64, eta::Float64, r::Float64)::Float64
    n_samples = 100
    Ed = 0.0
    # Precompute information for dipole integrand

    # Compute reduced scattering coefficients $\sigmaps, \sigmapt$ and albedo $\rhop$
    sigmap_s = sigma_s * (1.0 - g)
    sigmap_t = sigma_a + sigmap_s
    rhop = sigmap_s / sigmap_t

    # Compute non-classical diffusion coefficient $D_\roman{G}$ using Equation (15.24)
    D_g = (2.0 * sigma_a + sigmap_s) / (3.0 * sigmap_t * sigmap_t)

    # Compute effective transport coefficient $\sigmatr$ based on $D_\roman{G}$
    sigma_tr = sqrt(sigma_a / D_g)

    # Determine linear extrapolation distance $\depthextrapolation$ using Equation (15.28)
    fm1 = fresnel_moment_1(eta)
    fm2 = fresnel_moment_2(eta)
    ze = -2.0 * D_g * (1.0 + 3.0 * fm2) / (1.0 - 2.0 * fm1);

    # Determine exitance scale factors using Equations (15.31) and (15.32)
    cPhi = 0.25 * (1.0 - 2.0 * fm1)
    cE = 0.5 * (1.0 - 3.0 * fm2)
    for i in 0:(n_samples - 1)
        # Sample real point source depth $\depthreal$
        zr = -log(1 - (i + 0.5) / n_samples) / sigmap_t;

        # Evaluate dipole integrand $E_{\roman{d}}$ at $\depthreal$ and add to _Ed_
        zv = -zr + 2.0 * ze
        dr = sqrt(r * r + zr * zr)
        dv = sqrt(r * r + zv * zv)

        # Compute dipole fluence rate $\dipole(r)$ using Equation (15.27)
        phiD = (0.25 / pi) / D_g * (exp(-sigma_tr * dr) / dr - exp(-sigma_tr * dv) / dv)

        # Compute dipole vector irradiance $-\N{}\cdot\dipoleE(r)$ using Equation (15.27)
        EDn = (0.25 / pi) * (zr * (1 + sigma_tr * dr) *
            exp(-sigma_tr * dr) / (dr * dr * dr) -
            zv * (1 + sigma_tr * dv) *
            exp(-sigma_tr * dv) / (dv * dv * dv))

        # Add contribution from dipole for depth $\depthreal$ to _Ed_
        E = phiD * cPhi + EDn * cE;
        kappa = 1.0 - exp(-2.0 * sigmap_t * (dr + zr))
        Ed += kappa * rhop * rhop * E
    end
    return Ed / n_samples
end

function beam_diffusion_ss(sigma_s::Float64, sigma_a::Float64, g::Float64, eta::Float64, r::Float64)::Float64
    # Compute material parameters and minimum $t$ below the critical angle
    sigma_t = sigma_a + sigma_s
    rho = sigma_s / sigma_t
    tCrit = r * sqrt(eta * eta - 1)
    Ess = 0.0
    n_samples = 100
    for i in 0:(n_samples - 1)
        # Evaluate single scattering integrand and add to _Ess_
        ti = tCrit - log(1 - (i + 0.5) / n_samples) / sigma_t

        # Determine length $d$ of connecting segment and $\cos\theta_\roman{o}$
        d = sqrt(r * r + ti * ti)
        cosThetaO = ti / d

        # Add contribution of single scattering at depth $t$
        Ess += rho * exp(-sigma_t * (d + tCrit)) / (d * d) * 
            phase_HG(cosThetaO, g) * (1 - fresnel_dielectric(-cosThetaO, 1.0, eta)) *
            abs(cosThetaO)
    end
    return Ess / n_samples
end

function fresnel_moment_1(eta::Float64)::Float64
    if eta < 1.0
        return 0.45966 - 1.73965 * eta + 3.37668 * eta^2 - 3.904945 * eta^3 +
               2.49277 * eta^4 - 0.68441 * eta^5
    else
        return -4.61686 + 11.1136 * eta - 10.4646 * eta^2 + 5.11455 * eta^3 -
               1.27198 * eta^4 + 0.12746 * eta^5
    end
end

function fresnel_moment_2(eta::Float64)::Float64
    if eta < 1.0
        return 0.27614 - 0.87350 * eta + 1.12077 * eta^2 - 0.65095 * eta^3 +
               0.07883 * eta^4 + 0.04860 * eta^5
    else
        r_eta = 1.0 / eta
        return -547.033 + 45.3087 * (r_eta ^ 3) - 218.725 * (r_eta^2) +
               458.843 * r_eta + 404.557 * eta - 189.519 * eta^2 +
               54.9327 * eta^3 - 9.00603 * eta^4 + 0.63942 * eta^5
    end
end
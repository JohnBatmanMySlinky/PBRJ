struct BSSRDFTable
    n_rho_samples::Int64
    n_radius_samples::Int64
    rho_samples::SArray{}
    radius_samples::SArray{}
    profile::SArray{}
    rho_eff::SArray{}
    profile_cdf::SArray{}

    # equivalent to ComputeBeamDiffusionBSSRDF()
    function BSSRDF(g::Float64, eta::Float64)
        n_rho_samples = 100
        n_radius_samples = 64
        rho_samples = zeros(Float64, n_rho_samples)
        radius_samples = zeros(Float64, n_radius_samples)
        profile = zeros(Float64, n_rho_samples * n_radius_samples)
        rho_eff = zoers(Float64, n_rho_samples)
        profile_cdf = zeros(Float64, n_rho_samples * n_radius_samples)
        return new(n_rho_samples, n_radius_samples, rho_samples, radius_samples, profile, rho_eff, profile_cdf)
    end
end

function eval_profile(table::BSSRDF, rho_index::Int64, radius_index::Int64)::Float64
    return table.profile[rho_index * table.n_radius_samples + radius_index + 1]
end
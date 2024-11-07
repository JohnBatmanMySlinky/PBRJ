struct HairMaterial
	sigma_a::Maybe{Spectrum}     # spectrum
	color::Maybe{Spectrum}       # spectrum
	eumelanin::Maybe{Spectrum}   # float
	pheomelanin::Maybe{Spectrum} # float
	eta::Maybe{Spectrum}         # float
	beta_m::Maybe{Spectrum}      # float
	beta_n::Maybe{Spectrum}      # float
	alpha::Maybe{Spectrum}       # float
	
	function HairMaterial(
		sigma_a::Maybe{Spectrum},
		color::Maybe{Spectrum},
		eumelanin::Maybe{Spectrum},
		pheomelanin::Maybe{Spectrum},
		eta::Maybe{Spectrum},
		beta_m::Maybe{Spectrum},
		beta_n::Maybe{Spectrum},
		alpha::Maybe{Spectrum}
	)
		if !(sigma_a isa Nothing)
			@assert (color isa Nothing) & (eumelanin isa Nothing) & (pheomelanin isa Nothing)
		elseif !(color isa Nothing)
			@assert (sigma_a isa Nothing) & (eumelanin isa Nothing) & (pheomelanin isa Nothing)
		elseif !(eumelanin isa Nothing) | !(pheomelanin isa Nothing)
			@assert (sigma_a isa Nothing) & (color isa Nothing)
		end
		
		return new(color, eumelanin, pheomelanin, eta, beta_m, beta_n, alpha)
	end
end

function compute_scattering_functions!(
	hm::HairMaterial,
	si::SurfaceInteraction, 
	mode::TransportMode, 
	allow_multiple_lobes::Bool=false
)
	bm = hm.beta_m(si)
	bn = hm.beta_n(si)
	a = hm.alpha(si)
	e = hm.eta(si)
	
	if !(hm.sigma_a isa Nothing)
		sig_a = clamp(hm.sigma_a(si))
	elseif !(hm.color isa Nothing)
		c = clamp(hm.sigma_a(si))
		sig_a = sigma_a_from_reflectance(c, bn)
	else
		has_eumelanin = !(hm.eumelanin isa Nothing)
		has_pheomelanin = !(hm.pheomelanin isa Nothing)
		@assert has_eumelanin | has_pheomelanin
		sig_a = sigma_a_from_concentration(
			max(0.0, has_eumelanin ? hm.eumelanin(si) : 0.0),
			max(0.0, has_pheomelanin ? hm.pheomelanin(si) : 0.0),
		)
	end
	
	# offset along width
	h = -1.0 + 2.0 * si.uv.y
	si.bsdf = HairBSDF(h, e, sig_a, bm, bn, a)
end
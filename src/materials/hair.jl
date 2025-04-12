struct HairMaterial <: Material
	sigma_a::Maybe{Texture{Spectrum}}
	color::Maybe{Texture{Spectrum}}
	eumelanin::Maybe{Texture{Float64}}
	pheomelanin::Maybe{Texture{Float64}}
	eta::Maybe{Texture{Float64}}
	beta_m::Maybe{Texture{Float64}}
	beta_n::Maybe{Texture{Float64}}
	alpha::Maybe{Texture{Float64}}
	
	function HairMaterial(
		sigma_a::Maybe{Texture{Spectrum}},
		color::Maybe{Texture{Spectrum}},
		eumelanin::Maybe{Texture{Float64}},
		pheomelanin::Maybe{Texture{Float64}},
		eta::Maybe{Texture{Float64}},
		beta_m::Maybe{Texture{Float64}},
		beta_n::Maybe{Texture{Float64}},
		alpha::Maybe{Texture{Float64}}
	)
		if !(sigma_a isa Nothing)
			@assert (color isa Nothing) & (eumelanin isa Nothing) & (pheomelanin isa Nothing)
		elseif !(color isa Nothing)
			@assert (sigma_a isa Nothing) & (eumelanin isa Nothing) & (pheomelanin isa Nothing)
		elseif !(eumelanin isa Nothing) | !(pheomelanin isa Nothing)
			@assert (sigma_a isa Nothing) & (color isa Nothing)
		end

		if eta isa Nothing
			eta = ConstantTexture(1.55)
		end
		if beta_m isa Nothing
			beta_m = ConstantTexture(0.3)
		end
		if beta_n isa Nothing
			beta_n = ConstantTexture(0.3)
		end
		if alpha isa Nothing
			alpha = ConstantTexture(2.0)
		end
		
		return new(sigma_a, color, eumelanin, pheomelanin, eta, beta_m, beta_n, alpha)
	end
end

function (hm::HairMaterial)(si::SurfaceInteraction, ::Bool=false, ::Type{T}=Radiance) where T <: TransportMode
	bm = hm.beta_m(si)
	bn = hm.beta_n(si)
	a = hm.alpha(si)
	e = hm.eta(si)

	si.bsdf = BSDF(si, e)
	
	if !(hm.sigma_a isa Nothing)
		sig_a = clamp.(hm.sigma_a(si), 0.0, 1.0)
	elseif !(hm.color isa Nothing)
		c = clamp.(hm.color(si), 0.0, 1.0)
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
	add!(si.bsdf, HairBSDF(h, e, sig_a, bm, bn, a))
end

function sigma_a_from_concentration(ce::Float64, cp::Float64)::Spectrum
	eumelaninSigmaA = SVector(0.419, 0.697, 1.37)
    pheomelaninSigmaA = SVector(0.187, 0.4, 1.05)
	return spectrum_from_RGB(
		ce * eumelaninSigmaA[1] + cp * pheomelaninSigmaA[1],
		ce * eumelaninSigmaA[2] + cp * pheomelaninSigmaA[2],
		ce * eumelaninSigmaA[3] + cp * pheomelaninSigmaA[3],
	)
end

function sigma_a_from_reflectance(c::Spectrum, beta_n::Float64)::Spectrum
	tmp = (5.969 - 0.215 * beta_n + 2.532 * beta_n^2 - 10.73 * beta_n^3 + 5.574 * beta_n^4 + 0.245 * beta_n^5)
	return (log.(c) ./ tmp).^2
end
const pMax_hair::Int64 = 3

struct HairBSDF <: AbstractBSDF
	bxdf::BxDFType
	h::Float64
	gammaO::Float64
	eta::Float64
	sigma_a::Spectrum
	beta_m::Float64
	beta_n::Float64
	v::SVector{4, Float64}
	s::Float64
	sin_2_k_alpha::SVector{3, Float64}
	cos_2_k_alpha::SVector{3, Float64}
	
	function HairBSDF(
		h::Float64,
		eta::Float64,
		sigma_a::Spectrum,
		beta_m::Float64,
		beta_n::Float64,
		alpha::Float64
	)
		bxdf = BSDF_GLOSSY | BSDF_REFLECTION | BSDF_TRANSMISSION
		@assert (h >= -1) && (h <= 1)
		@assert (beta_m >= 0) && (beta_m <= 1)
		@assert (beta_n >= 0) && (beta_n <= 1)
		
		# computre longitudinal variance from $\beta_m$
		v0 = (0.726 * beta_m + 0.812 * beta_m^2 + 3.7 * beta_m^20)^2
		v = SVector(
			v0,
			0.25 * v0,
			4 * v0,
			4 * v0
		)
		@assert length(v) == pMax_hair
		
		# Compute azimuthal logistic scale factor from $\beta_n$
		s = sqrt(pi) * (0.265 * beta_n + 1.194 * beta_n^2 + 5.372 * beta_n^22) / 8.0
		@assert !isinf(s)
	
		# compute $\alpha$ terms for hair scales
		sin_2_k_alpha = zeros(3, Float64)
		cos_2_k_alpha = zeros(3, Float64)
		sin_2_k_alpha[0+1] = sin(radians(alpha))
		cos_2_k_alpha[0+1] = safe_sqrt(1-sin_2_k_alpha[0+1]^2)
		for i in 1:2
			sin_2_k_alpha[i+1] = 2 * cos_2_k_alpha[i-1+1] * sin_2_k_alpha[i-1+1]
			cos_2_k_alpha[i+1] = cos_2_k_alpha[i-1+1]^2 - sin_2_k_alpha[i-1+1]^2
		end
		return new(
			bxdf,
			h,
			safe_a_sin(h),
			eta,
			sigma_a,
			beta_m,
			beta_n,
			v,
			s,
			SVector(sin_2_k_alpha),
			SVector(cos_2_k_alpha)
		)
	end
end

function f(hair::HairBSDF, wo::Vec3, wi::Vec3)::Spectrum
	# Compute hair coordinate system terms related to _wo_
    sin_theta_o = wo.x
    cos_theta_o = safe_sqrt(1 - sin_theta_o^2)
    phi_O = atan2(wo.z, wo.y)

    # Compute hair coordinate system terms related to _wi_
    sin_theta_I = wi.x
    cos_theta_I = safe_sqrt(1-sin_theta_I^2)
    phi_I = atan2(wi.z, wi.y)

    # Compute $\cos \thetat$ for refracted ray
    sin_theta_T = sinThetaO / eta;
    cos_theta_T = safe_sqrt(1-sin_theta_T^2)

    # Compute $\gammat$ for refracted ray
    etap = sqrt(eta^2 - sin_theta_o^2) / cos_theta_o
    sin_gamma_T = h / etap
    cos_tamma_T = safe_sqrt(1-sin_gamma_T^2)
    gamma_T = safe_a_sin(sin_gamma_T)

    # Compute the transmittance _T_ of a single path through the cylinder
    T = exp.(-sigma_a * (2 * cos_tamma_T / cos_theta_T))

    # Evaluate hair BSDF
    phi = phi_I - phi_O
    ap = Ap(cos_theta_o, eta, h, T)
    fsum = spectrum_from_float(0.0)
    for p in 0:(pMax_hair-1)
        # Compute $\sin \thetao$ and $\cos \thetao$ terms accounting for scales
        if p == 0
            sin_theta_Op = sin_theta_o * hair.cos_2_k_alpha[1+1] - cos_theta_o * hair.sin_2_k_alpha[1+1]
            cos_theta_Op = cos_theta_o * hair.cos_2_k_alpha[1+1] + sin_theta_o * hair.sin_2_k_alpha[1+1]
		# Handle remainder of $p$ values for hair scale tilt
        elseif p == 1
            sin_theta_Op = sin_theta_o * cos2kAlpha[0] + cos_theta_o * sin2kAlpha[0];
            cos_theta_Op = cos_theta_o * cos2kAlpha[0] - sin_theta_o * sin2kAlpha[0];
        elseif p == 2
            sin_theta_Op = sin_theta_o * cos2kAlpha[2] + cos_theta_o * sin2kAlpha[2];
            cos_theta_Op = cos_theta_o * cos2kAlpha[2] - sin_theta_o * sin2kAlpha[2];
        else
            sin_theta_Op = sin_theta_o;
            cos_theta_Op = cos_theta_o;
        end

        # Handle out-of-range $\cos \thetao$ from scale adjustment
        cos_theta_Op = abs(cos_theta_Op)
        fsum += Mp(
			cos_theta_I,
			cos_theta_Op, 
			sin_theta_I, 
			sin_theta_Op, 
			v[p+1]
		) * ap[p+1] * Np(
			phi, 
			p, 
			s, 
			gamma_O, gamma_T
		)
    end

    # Compute contribution of remaining terms after _pMax_
    fsum += Mp(
		cos_theta_I, 
		cos_theta_O, 
		sin_theta_I, 
		sin_theta_O, 
		v[pMax+1]
	) * ap[pMax+1] / (2.0 * pi)
    if (abs_cos_theta(wi) > 0) 
		fsum /= abs_cos_theta(wi)
	end
    CHECK(!std::isinf(fsum.y()) && !std::isnan(fsum.y()));
    return fsum
end


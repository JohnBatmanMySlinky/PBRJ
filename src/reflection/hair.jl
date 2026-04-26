const pMax_hair::Int64 = 3

struct HairBSDF <: AbstractBxDF
	type::UInt8
	h::Float64
	gamma_O::Float64
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
		@assert (h >= -1) & (h <= 1)
		@assert (beta_m >= 0) & (beta_m <= 1)
		@assert (beta_n >= 0) & (beta_n <= 1)
		
		# computre longitudinal variance from $\beta_m$
		v0 = (0.726 * beta_m + 0.812 * beta_m^2 + 3.7 * beta_m^20)^2
		v = SVector(
			v0,
			0.25 * v0,
			4 * v0,
			4 * v0
		)
		@assert length(v) == pMax_hair + 1
		
		# Compute azimuthal logistic scale factor from $\beta_n$
		s = 0.626657069 * (0.265 * beta_n + 1.194 * beta_n^2 + 5.372 * beta_n^22)
		@assert !isinf(s)
	
		# compute $\alpha$ terms for hair scales
		sin_2_k_alpha = zeros(Float64, 3)
		cos_2_k_alpha = zeros(Float64, 3)
		sin_2_k_alpha[0+1] = sin(deg2rad(alpha))
		cos_2_k_alpha[0+1] = safe_sqrt(1-sin_2_k_alpha[0+1]^2)
		for i in 1:2
			sin_2_k_alpha[i+1] = 2 * cos_2_k_alpha[i-1+1] * sin_2_k_alpha[i-1+1]
			cos_2_k_alpha[i+1] = cos_2_k_alpha[i-1+1]^2 - sin_2_k_alpha[i-1+1]^2
		end

		# println("V: $v")
		# println("sin_2_k_alpha: $sin_2_k_alpha")
		# println("cos_2_k_alpha: $cos_2_k_alpha")

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
			SVector{3}(sin_2_k_alpha),
			SVector{3}(cos_2_k_alpha)
		)
	end
end

function f(hair::HairBSDF, wo::Vec3, wi::Vec3)::Spectrum
	# Compute hair coordinate system terms related to _wo_
    sin_theta_o = wo.x
    cos_theta_o = safe_sqrt(1 - sin_theta_o^2)
    phi_O = atan(wo.z, wo.y)

    # Compute hair coordinate system terms related to _wi_
    sin_theta_I = wi.x
    cos_theta_I = safe_sqrt(1-sin_theta_I^2)
    phi_I = atan(wi.z, wi.y)

    # Compute $\cos \thetat$ for refracted ray
    sin_theta_T = sin_theta_o / hair.eta
    cos_theta_T = safe_sqrt(1-sin_theta_T^2)

    # Compute $\gammat$ for refracted ray
    etap = sqrt(hair.eta^2 - sin_theta_o^2) / cos_theta_o
    sin_gamma_T = hair.h / etap
    cos_tamma_T = safe_sqrt(1-sin_gamma_T^2)
    gamma_T = safe_a_sin(sin_gamma_T)

    # Compute the transmittance _T_ of a single path through the cylinder
    T = exp.(-hair.sigma_a * (2 * cos_tamma_T / cos_theta_T))

    # Evaluate hair BSDF
    phi = phi_I - phi_O
    ap = Ap(cos_theta_o, hair.eta, hair.h, T)
    fsum = spectrum_from_float(0.0)
    for p in 0:(pMax_hair-1)
        # Compute $\sin \thetao$ and $\cos \thetao$ terms accounting for scales
        if p == 0
            sin_theta_Op = sin_theta_o * hair.cos_2_k_alpha[1+1] - cos_theta_o * hair.sin_2_k_alpha[1+1]
            cos_theta_Op = cos_theta_o * hair.cos_2_k_alpha[1+1] + sin_theta_o * hair.sin_2_k_alpha[1+1]
		# Handle remainder of $p$ values for hair scale tilt
        elseif p == 1
            sin_theta_Op = sin_theta_o * hair.cos_2_k_alpha[0+1] + cos_theta_o * hair.sin_2_k_alpha[0+1]
            cos_theta_Op = cos_theta_o * hair.cos_2_k_alpha[0+1] - sin_theta_o * hair.sin_2_k_alpha[0+1]
        elseif p == 2
            sin_theta_Op = sin_theta_o * hair.cos_2_k_alpha[2+1] + cos_theta_o * hair.sin_2_k_alpha[2+1]
            cos_theta_Op = cos_theta_o * hair.cos_2_k_alpha[2+1] - sin_theta_o * hair.sin_2_k_alpha[2+1]
        else
            sin_theta_Op = sin_theta_o
            cos_theta_Op = cos_theta_o
        end

        # Handle out-of-range $\cos \thetao$ from scale adjustment
        cos_theta_Op = abs(cos_theta_Op)
		mp = Mp(
			cos_theta_I,
			cos_theta_Op, 
			sin_theta_I, 
			sin_theta_Op, 
			hair.v[p+1]
		)
		np = Np(
			phi, 
			p, 
			hair.s, 
			hair.gamma_O, 
			gamma_T
		)
		# println("mp: $mp")
		# println("phi: $phi p: $p s: $(hair.s) gamma_o: $(hair.gamma_O) gamma_t: $gamma_T ")
		# println("np: $np")
		# println("ap: $(ap[p+1])")
        fsum += mp * ap[p+1] * np
    end

	# Compute contribution of remaining terms after _pMax_
    fsum += Mp(
		cos_theta_I, 
		cos_theta_o, 
		sin_theta_I, 
		sin_theta_o, 
		hair.v[pMax_hair+1]
	) * ap[pMax_hair+1] / (2.0 * pi)
    if (abs_cos_theta(wi) > 0) 
		fsum /= abs_cos_theta(wi)
	end
    if !(!isinf(y_spectrum(fsum)) && !isnan(y_spectrum(fsum)))
		# print("end")
		# println(fsum)
		@assert false
	end
    return fsum
end

function sample_f(hair::HairBSDF, wo::Vec3, u2::Pnt2, type::UInt8)::Tuple{Vec3, Spectrum, Float64, Maybe{UInt8}}
	# Compute hair coordinate system terms related to _wo_
	sin_theta_O = wo.x
	cos_theta_O = safe_sqrt(1 - sin_theta_O^2)
	phi_O = atan(wo.z, wo.y)

	# Derive four random samples from _u2_
	u1 = demux_float(Float32(u2.x))
	u2 = demux_float(Float32(u2.y))
	u00 = u1.x
	u01 = u1.y
	u10 = u2.x
	u11 = u2.y

	# Determine which term $p$ to sample for hair scattering
	ap_pdf = compute_Ap_pdf(hair, cos_theta_O)
	p = 0
	for i in 0:(pMax_hair-1)
		if u00 < ap_pdf[i+1]
			p = i
			break
		end
		u00 -= ap_pdf[i+1]
	end

	# Rotate $\sin \thetao$ and $\cos \thetao$ to account for hair scale tilt
	if p == 0
		sin_theta_op = sin_theta_O * hair.cos_2_k_alpha[1+1] - cos_theta_O * hair.sin_2_k_alpha[1+1]
		cos_theta_op = cos_theta_O * hair.cos_2_k_alpha[1+1] + sin_theta_O * hair.sin_2_k_alpha[1+1]
	elseif p == 1
		sin_theta_op = sin_theta_O * hair.cos_2_k_alpha[0+1] + cos_theta_O * hair.sin_2_k_alpha[0+1]
		cos_theta_op = cos_theta_O * hair.cos_2_k_alpha[0+1] - sin_theta_O * hair.sin_2_k_alpha[0+1]
	elseif p == 2
		sin_theta_op = sin_theta_O * hair.cos_2_k_alpha[2+1] + cos_theta_O * hair.sin_2_k_alpha[2+1]
		cos_theta_op = cos_theta_O * hair.cos_2_k_alpha[2+1] - sin_theta_O * hair.sin_2_k_alpha[2+1]
	else
		sin_theta_op = sin_theta_O
		cos_theta_op = cos_theta_O
	end

	# Sample $M_p$ to compute $\thetai$
	u10 = max(u10, 1e-5)
	cos_theta = 1 + hair.v[p+1] * log(u10 + (1 - u10) * exp(-2 / hair.v[p+1]))
	sin_theta = safe_sqrt(1 - cos_theta^2)
	cos_phi = cos(2 * pi * u11)
	sin_theta_I = -cos_theta * sin_theta_op + sin_theta * cos_phi * cos_theta_op
	cos_theta_I = safe_sqrt(1 - sin_theta_I^2)
	
	# Sample $N_p$ to compute $\Delta\phi$
	# Compute $\gammat$ for refracted ray
	etap = sqrt(hair.eta^2 - sin_theta_O^2) / cos_theta_O
	sin_gamma_T = hair.h / etap
	gamma_T = safe_asin(sin_gamma_T)
	if (p < pMax_hair)
		dphi = phi(p, hair.gamma_O, gamma_T) + sample_trimmed_logistic(u01, hair.s, -pi, Float64(pi))
	else
		dphi = 2 * pi * u01
	end

	# Compute _wi_ from sampled hair scattering angles
	phi_I = phi_O + dphi
	wi = Vec3(sin_theta_I, cos_theta_I * cos(phi_I), cos_theta_I * sin(phi_I))

	# Compute PDF for sampled hair scattering direction _wi_
	pdf_val = 0.0
	for p in 0:(pMax_hair-1)
		# Compute $\sin \thetao$ and $\cos \thetao$ terms accounting for scales
		if p == 0
			sin_theta_op = sin_theta_O * hair.cos_2_k_alpha[1+1] - cos_theta_O * hair.sin_2_k_alpha[1+1]
			cos_theta_op = cos_theta_O * hair.cos_2_k_alpha[1+1] + sin_theta_O * hair.sin_2_k_alpha[1+1]

		# Handle remainder of $p$ values for hair scale tilt
		elseif p == 1
			sin_theta_op = sin_theta_O * hair.cos_2_k_alpha[0+1] + cos_theta_O * hair.sin_2_k_alpha[0+1]
			cos_theta_op = cos_theta_O * hair.cos_2_k_alpha[0+1] - sin_theta_O * hair.sin_2_k_alpha[0+1]
		elseif p == 2
			sin_theta_op = sin_theta_O * hair.cos_2_k_alpha[2+1] + cos_theta_O * hair.sin_2_k_alpha[2+1]
			cos_theta_op = cos_theta_O * hair.cos_2_k_alpha[2+1] - sin_theta_O * hair.sin_2_k_alpha[2+1]
		else
			sin_theta_op = sin_theta_O
			cos_theta_op = cos_theta_O
		end

		# Handle out-of-range $\cos \thetao$ from scale adjustment
		cos_theta_op = abs(cos_theta_op)
		pdf_val += Mp(cos_theta_I, cos_theta_op, sin_theta_I, sin_theta_op, hair.v[p+1]) * ap_pdf[p+1] * Np(dphi, p, hair.s, hair.gamma_O, gamma_T)
	end
	pdf_val += Mp(cos_theta_I, cos_theta_O, sin_theta_I, sin_theta_O, hair.v[pMax_hair+1]) * ap_pdf[pMax_hair+1] * (1 / (2 * pi))
	return wi, f(hair, wo, wi), pdf_val, hair.type
end

function compute_pdf(hair::HairBSDF, wo::Vec3, wi::Vec3)::Float64
    # Compute hair coordinate system terms related to _wo_
    sin_theta_O = wo.x
    cos_theta_O = safe_sqrt(1.0 - sin_theta_O^2)
    phi_O = atan(wo.z, wo.y)

    # Compute hair coordinate system terms related to _wi_
    sin_theta_I = wi.x
    cos_theta_I = safe_sqrt(1.0 - sin_theta_I^2)
    phi_I = atan(wi.z, wi.y)

    # Compute $\gammat$ for refracted ray
    eta_p = sqrt(hair.eta * hair.eta - sin_theta_O^2) / cos_theta_O
    sin_gamma_T = hair.h / eta_p
    gamma_T = safe_a_sin(sin_gamma_T)

    # Compute PDF for $A_p$ terms
    ap_pdf = compute_Ap_pdf(hair, cos_theta_O)

    # Compute PDF sum for hair scattering events
    phi = phi_I - phi_O
    pdf_val = 0.0
    for p in 0:(pMax_hair-1)
        # Compute $\sin \thetao$ and $\cos \thetao$ terms accounting for scales
        if p == 0
            sin_theta_Op = sin_theta_O * hair.cos_2_k_alpha[1+1] - cos_theta_O * hair.sin_2_k_alpha[1+1]
            cos_theta_Op = cos_theta_O * hair.cos_2_k_alpha[1+1] + sin_theta_O * hair.sin_2_k_alpha[1+1]
		# Handle remainder of $p$ values for hair scale tilt
        elseif p == 1
            sin_theta_Op = sin_theta_O * hair.cos_2_k_alpha[0+1] + cos_theta_O * hair.sin_2_k_alpha[0+1]
            cos_theta_Op = cos_theta_O * hair.cos_2_k_alpha[0+1] - sin_theta_O * hair.sin_2_k_alpha[0+1]
        elseif p == 2
            sin_theta_Op = sin_theta_O * hair.cos_2_k_alpha[2+1] + cos_theta_O * hair.sin_2_k_alpha[2+1]
            cos_theta_Op = cos_theta_O * hair.cos_2_k_alpha[2+1] - sin_theta_O * hair.sin_2_k_alpha[2+1]
        else
            sin_theta_Op = sin_theta_O
            cos_theta_Op = cos_theta_O
        end

        # Handle out-of-range $\cos \thetao$ from scale adjustment
        cos_theta_Op = abs(cos_theta_Op)
        mp = Mp(
			cos_theta_I, 
			cos_theta_Op, 
			sin_theta_I, 
			sin_theta_Op, 
			hair.v[p+1]
		) 
		np = Np(
			phi, 
			p, 
			hair.s, 
			hair.gamma_O, 
			gamma_T
		)

		pdf_val += mp * ap_pdf[p+1] * np
    end
	mp = Mp(
		cos_theta_I, 
		cos_theta_O, 
		sin_theta_I, 
		sin_theta_O, hair.v[pMax_hair+1])
    pdf_val += mp * ap_pdf[pMax_hair+1] / (2.0 * pi)
    return pdf_val
end


function compute_Ap_pdf(hair:: HairBSDF, cos_theta_O::Float64)::SVector{4, Float64}
	# Compute array of $A_p$ values for _cosThetaO_
    sin_theta_O = safe_sqrt(1.0 - cos_theta_O^2)

    # Compute $\cos \thetat$ for refracted ray
    sin_theta_T = sin_theta_O / hair.eta
    cos_theta_T = safe_sqrt(1 - sin_theta_T^2)

    # Compute $\gammat$ for refracted ray
    etap = sqrt(hair.eta^2 - sin_theta_O^2) / cos_theta_O
    sin_gamma_T = hair.h / etap
    cos_gamma_T = safe_sqrt(1 - sin_gamma_T^2)

    # Compute the transmittance _T_ of a single path through the cylinder
    T = exp.(-hair.sigma_a * (2 * cos_gamma_T / cos_theta_T))
    ap = Ap(cos_theta_O, hair.eta, hair.h, T)

    # Compute $A_p$ PDF from individual $A_p$ terms
    sum_y = sum(y_spectrum, ap)
    return SVector(
		y_spectrum(ap[1]) / sum_y,
		y_spectrum(ap[2]) / sum_y,
		y_spectrum(ap[3]) / sum_y,
		y_spectrum(ap[4]) / sum_y
	)
end

function sample_trimmed_logistic(u::Float64, s::Float64, a::Float64, b::Float64)::Float64
	@assert a < b
	k = logistic_CDF(b,s) - logistic_CDF(a, s)
	x = -s * log(1 / (u * k + logistic_CDF(a, s)) - 1)
    @assert !isnan(x)
    return clamp(x, a, b)
end

function demux_float(f::Float32)::Pnt2
    # @assert 0.0 <= f < 1.0
	# JOHN HACK cuz Float32(1.0-eps()) = 1.0f0
	f = clamp(f, 0.0, 1.0-eps(Float32))
    v = UInt64(floor(f * (1 << 32)))
    @assert v < 0x100000000

    return Pnt2(compact1by1(v % UInt32) / Float64(1 << 16), compact1by1((v >> 1)% UInt32) / Float64(1 << 16))
end

function compact1by1(x::UInt32)::UInt32
    # Apply bitmask and shifts to interleave bits as in the original C++ code
    x &= 0x55555555
    x = (x ⊻ (x >> 1)) & 0x33333333
	x = (x ⊻ (x >> 2)) & 0x0f0f0f0f
	x = (x ⊻ (x >> 4)) & 0x00ff00ff
	x = (x ⊻ (x >> 8)) & 0x0000ffff
	return x
end

function safe_a_sin(x::Float64)::Float64
	return asin(clamp(x, -1.0, 1.0))
end

function Ap(cos_theta_O::Float64, eta::Float64, h::Float64, T::Spectrum)::SVector{4, Spectrum}
	cos_gamma_O = safe_sqrt(1.0 - h^2)
	cos_theta = cos_theta_O * cos_gamma_O
	f = fresnel_dielectric(cos_theta, 1.0, eta)
	return SVector{4}(
		spectrum_from_float(f), # JOhn hack; how does pbrt convert float to spectrum?
		(1.0 - f).^2 * T,
		(1.0 - f).^2 * T.^2 * f,
		(1.0 - f).^2 * T.^3 * f.^2 ./ (spectrum_from_float(1.0) - T * f),
	)
end

function Mp(cos_theta_I::Float64, cos_theta_O::Float64, sin_theta_I::Float64, sin_theta_O::Float64, v::Float64)::Float64
	a = cos_theta_I * cos_theta_O / v
    b = sin_theta_I * sin_theta_O / v
    mp = (v <= 0.1) ? (exp(log_I0(a) - b - 1 / v + 0.69310 + log(1 / (2 * v)))) : (exp(-b) * I0(a)) / (sinh(1 / v) * 2 * v)
	@assert !isinf(mp) && !isnan(mp)
    return mp
end

function I0(x::Float64)::Float64
	val = 0.0
	x2i = 1.0
	ifact = 1
	i4 = 1
	# I0(x) \approx Sum_i x^(2i) / (4^i (i!)^2)
	for i in 0:9
		if i > 1
			ifact *= i
		end
		val += x2i / (i4 * ifact^2)
		x2i *= x^2
		i4 *= 4
	end
	return val
end

function log_I0(x::Float64)::Float64
	if x > 12
        return x + 0.5 * (-log(2 * pi) + log(1 / x) + 1 / (8 * x))
    else
        return log(I0(x))
	end
end

function phi(p::Int64, gamma_O::Float64, gamma_T::Float64)::Float64
    return 2.0 * p * gamma_T - 2.0 * gamma_O + p * pi
end

function logistic(x::Float64, s::Float64)::Float64
    x = abs(x)
    return exp(-x / s) / (s * (1 + exp(-x / s))^2)
end

function logistic_CDF(x::Float64, s::Float64)::Float64
    return 1 / (1 + exp(-x / s))
end

function trimmed_logistic(x::Float64, s::Float64, a::Float64, b::Float64)::Float64
	return logistic(x,s) / (logistic_CDF(b,s) - logistic_CDF(a,s))
end

function Np(phi_p::Float64, p::Int64, s::Float64, gamma_O::Float64, gamma_T::Float64)::Float64
    dphi = phi_p - phi(p, gamma_O, gamma_T)
    # Remap _dphi_ to $[-\pi,\pi]$
    while (dphi > pi) 
		dphi -= 2 * pi
	end
    while (dphi < -pi) 
		dphi += 2 * pi
	end
    return trimmed_logistic(dphi, s, -pi, Float64(pi))
end
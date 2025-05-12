struct FourierBSDF <: AbstractBxDF
    table::FourierBSDFTable
    mode::Type{T} where T <: TransportMode
    type::UInt8
end

function f(f::FourierBSDF, wo::Vec3, wi::Vec3)::Spectrum
    @info "FourierBSDF::f"
    # Find the zenith angle cosines and azimuth difference angle
    mu_I = cos_theta(-wi)
    mu_O = cos_theta(wo)
    cos_phi = cos_d_phi(-wi, wo)
    
    # Compute Fourier coefficients $a_k$ for $(\mu_I, \mu_O)$
    # Determine offsets and weights for $\mu_I$ and $\mu_O$
    check_I, offset_I, weights_I = get_weights_and_offset(f.table, mu_I)
    check_O, offset_O, weights_O = get_weights_and_offset(f.table, mu_O)
    if (!check_I) || (!check_O)
        return spectrum_from_float(0.0)
    end

    # Allocate storage to accumulate _ak_ coefficients
    ak = zeros(f.table.mMax * f.table.nChannels)

    # Accumulate weighted sums of nearby $a_k$ coefficients
    for b in 0:3
        for a in 0:3
            # Add contribution of _(a, b)_ to $a_k$ values
            weight = weights_I[a+1] * weights_O[b+1]
            if weight != 0.0
                ap, m = get_ak(f.table, offset_I + a, offset_O + b)
                mMax = max(f.table.mMax, m)
                for c in 0:(f.table.nChannels - 1)
                    for k in 0:(m-1)
                        ak[c * mMax + k + 1] += weight * ap[c * m + k + 1]
                    end
                end
            end
        end
    end

    # Evaluate Fourier expansion for angle $\phi$
    Y = max(0.0, Fourier(ak, mMax, cos_phi))
    scale = (mu_I != 0.0 ? (1.0 / abs(mu_I)) : 0.0)

    # Update _scale_ to account for adjoint light transport
    if ((mode == Radiance) && (mu_I * mu_O > 0.0))
        eta = mu_I > 0.0 ? 1.0 / f.table.eta : f.table.eta
        scale *= eta * eta
    end

    if f.table.nChannels == 1
        return spectrum_from_float(Y * scale)
    else
        # Compute and return RGB colors for tabulated BSDF
        R = fourier_interpolation(ak + 1 * f.table.mMax, f.table.mMax, cos_phi)
        B = fourier_interpolation(ak + 2 * f.table.mMax, f.table.mMax, cos_phi)
        G = 1.39829 * Y - 0.100913 * B - 0.297375 * R
        return clamp.(spectrum_from_float(R * scale, G * scale, B * scale), 0.0, 1.0) # JOHN HACK ON CLAMP
    end
end

function sample_f(f::FourierBSDF, wo::Vec3, u::Pnt2, type::UInt8=BSDF_ALL)::Tuple{Vec3, Spectrum, Float64, Maybe{UInt8}}
    @info "FourierBSDF::sample_f"
    @info "FourierBSDF::sample_f: wo = $wo"
    @info "FourierBSDF::sample_f: u = $u"
    # Sample zenith angle component for _FourierBSDF_
    mu_O = cos_theta(wo)
    mu_I, _, pdf_mu = sample_catmull_rom_2D(
        f.table.nMu, 
        f.table.nMu, 
        f.table.mu,                           
        f.table.mu,
        f.table.a0, 
        f.table.cdf,
        mu_O, 
        u[1+1], 
    )

    # Compute Fourier coefficients $a_k$ for $(\mu_I, \mu_O)$
    # Determine offsets and weights for $\mu_I$ and $\mu_O$
    check_I, offset_I, weights_I = get_weights_and_offset(f.table, mu_I)
    check_O, offset_O, weights_O = get_weights_and_offset(f.table, mu_O)
    if (!check_I) || (!check_O)
        return spectrum_from_float(0.0)
    end

    # Sample zenith angle component for _FourierBSDF_
    # Compute Fourier coefficients $a_k$ for $(\mu_I, \mu_O)$

    # Allocate storage to accumulate _ak_ coefficients
    ak = zeros(Float64, f.table.mMax * f.table.nChannels)

    # Accumulate weighted sums of nearby $a_k$ coefficients
    mMax = 0
    for b in 0:3
        for a in 0:3
            # Add contribution of _(a, b)_ to $a_k$ values
            weight = weights_I[a + 1] * weights_O[b + 1]
            if weight != 0.0
                ap, m = get_ak(f.table, offset_I + a, offset_O + b)
                mMax = max(mMax, m)
                for c in 0:(f.table.nChannels - 1)
                    for k in 0:(m - 1)
                        ak[c * f.table.mMax + k + 1] += weight * ap[c * m + k + 1]
                        @info "FourierBSDF::Sample_f::a_k: b: $b, a: $a, c: $c, k: $k, $m, ap: $(ap[c * m + k + 1])"
                    end
                end
            end
        end
    end

    # Importance sample the luminance Fourier expansion
    Y, pdf_phi, phi = SampleFourier(ak, f.table.recip, mMax, u[0+1])
    pdf_val = max(0.0, pdf_phi * pdf_mu)

    # Compute the scattered direction for _FourierBSDF_
    sin2ThetaI = max(0.0, 1.0 - mu_I ^ 2)
    norm = sqrt(sin2ThetaI / sin_2_theta(wo))
    if isinfinite(norm) 
        norm = 0.0
    end
    sin_phi = sin(phi) 
    cos_phi = cos(phi)
    wi = -Vec3(
        norm * (cos_phi * wo.x - sin_phi * wo.y),
        norm * (sin_phi * wo.x + cos_phi * wo.y), 
        mu_I
    )

    # Mathematically, wi will be normalized (if wo was). However, in
    # practice, floating-point rounding error can cause some error to
    # accumulate in the computed value of wi here. This can be
    # catastrophic: if the ray intersects an object with the FourierBSDF
    # again and the wo (based on such a wi) is nearly perpendicular to the
    # surface, then the wi computed at the next intersection can end up
    # being substantially (like 4x) longer than normalized, which leads to
    # all sorts of errors, including negative spectral values. Therefore,
    # we normalize again here.
    wi = normalize(wi)

    # Evaluate remaining Fourier expansions for angle $\phi$
    scale = mu_I != 0.0 ? (1.0 / abs(mu_I)) : 0.0
    if ((mode == Radiance) && (mu_I * mu_O > 0.0))
        eta = mu_I > 0.0 ? 1 / f.table.eta : f.table.eta
        scale *= eta * eta
    end

    if (f.table.nChannels == 1) 
        return spectrum_from_float(Y * scale)
    end
    R = fourier_interpolation(ak + 1 * f.table.mMax, mMax, cos_phi)
    B = fourier_interpolation(ak + 2 * f.table.mMax, mMax, cos_phi)
    G = 1.39829 * Y - 0.100913 * B - 0.297375 * R
    return clamp.(spectrum_from_float(R * scale, G * scale, B * scale), 0.0, 1.0) # JOHN HACK ON CLAMP
end


function compute_pdf(f::FourierBSDF, wo::Vec3, wi::Vec3)::Float64
    @info "FourierBSDF::compute_pdf"
    # Find the zenith angle cosines and azimuth difference angle
    mu_I = cos_theta(-wi)
    mu_O = cos_theta(wo)
    cos_phi = cos_d_phi(-wi, wo)

    # Compute Fourier coefficients $a_k$ for $(\mu_I, \mu_O)$
    # Determine offsets and weights for $\mu_I$ and $\mu_O$
    check_I, offset_I, weights_I = get_weights_and_offset(f.table, mu_I)
    check_O, offset_O, weights_O = get_weights_and_offset(f.table, mu_O)
    if (!check_I) || (!check_O)
        return spectrum_from_float(0.0)
    end

    # Allocate storage to accumulate _ak_ coefficients
    ak = zeros(f.table.mMax * f.table.nChannels)

    # Accumulate weighted sums of nearby $a_k$ coefficients
    for b in 0:3
        for a in 0:3
            # Add contribution of _(a, b)_ to $a_k$ values
            weight = weights_I[a+1] * weights_O[b+1]
            if weight != 0.0
                ap, m = get_ak(f.table, offset_I + a, offset_O + b)
                mMax = max(f.table.mMax, m)
                for c in 0:(f.table.nChannels - 1)
                    for k in 0:(m-1)
                        ak[c * mMax + k + 1] += weight * ap[c * m + k + 1]
                    end
                end
            end
        end
    end

    # Evaluate probability of sampling _wi_
    rho = 0.0
    for o in 0:3
        if weights[o+1] == 0
            continue
        end
        rho += weightsO[o] *
            f.table.cdf[(offsetO + o) * f.table.nMu + f.table.nMu - 1 + 1] *
            (2 * pi)
    end
    Y = fourier_interpolation(ak, mMax, cos_phi)
    return (rho > 0 && Y > 0) ? (Y / rho) : 0
end

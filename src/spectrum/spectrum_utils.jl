function Base.convert(::Type{Float64}, s::Spectrum)
    return y_spectrum(s)
end

function lerp(t::Float64, a::Float64, b::Float64)::Float64
    return (1.0 - t) * a + t * b
end

function check_monotonic(a::Vector{Float64})::Bool
    l = length(a)
    for i in 1:(l-1)
        if a[i] > a[i+1]
            return false
        end
    end
    return true
end

function average_spectrum_samples(
    lambda::Vector{Float64}, 
    vals::Vector{Float64}, 
    n::Int64, 
    lambda_start::Float64, 
    lambda_end::Float64
)::Float64
    # Handle cases with out-of-bounds range or single sample only
    (lambda_end <= lambda[0+1]) && (return vals[0+1])
    (lambda_start >= lambda[n-1+1]) && (return vals[n-1+1])
    (n == 1) && (return vals[0+1])

    tot = 0.0
    # Add contributions of constant segments before/after samples
    if (lambda_start < lambda[0+1]) 
        tot += vals[0+1] * (lambda[0+1] - lambda_start)
    end
    if (lambda_end > lambda[n-1+1])
        tot += vals[n-1+1] * (lambda_end - lambda[n-1+1])
    end

    # Advance to first relevant wavelength segment
    i = 0+1
    while (lambda_start > lambda[i + 1])
        i += 1
    end
    @assert i + 1 <= n

    # Loop over wavelength sample segments and add contributions
    while (i+1<=n) && (lambda_end >= lambda[i])
        seg_lambda_start = max(lambda_start, lambda[i])
        seg_lambda_end = min(lambda_end, lambda[i+1])
        a = lerp(
            (seg_lambda_start-lambda[i])/(lambda[i+1]-lambda[i]),
            vals[i],
            vals[i+1]
        )
        b = lerp(
            (seg_lambda_end-lambda[i])/(lambda[i+1]-lambda[i]),
            vals[i],
            vals[i+1]
        )
        tot += 0.5*(a+b)*(seg_lambda_end-seg_lambda_start)
        i += 1
    end
    return tot / (lambda_end-lambda_start)
end

function is_black(x::Spectrum)::Bool
    return all(iszero, x)
end

@inline function Base.:*(a::Spectrum, b::Spectrum)::Spectrum
    return Spectrum(ntuple(i -> @inbounds(a[i] * b[i]), Val(nSpectralSamples)))
end

function XYZ_to_RGB(xyz::XYZPBRT)::RGBPBRT
    return RGBPBRT(
        3.240479  * xyz.x - 1.537150 * xyz.y - 0.498535 * xyz.z,
        -0.969256 * xyz.x + 1.875991 * xyz.y + 0.041556 * xyz.z,
        0.055648  * xyz.x - 0.204043 * xyz.y + 1.057311 * xyz.z,
    )
end
function RGB_to_XYZ(s::Spectrum)::XYZPBRT
    return XYZPBRT(
        0.412453 * s[1] + 0.357580 * s[2] + 0.180423 * s[3],
        0.212671 * s[1] + 0.715160 * s[2] + 0.072169 * s[3],
        0.019334 * s[1] + 0.119193 * s[2] + 0.950227 * s[3],
    )
end

function to_XYZ(s::Spectrum)::XYZPBRT
    if length(s) == 3
        return RGB_to_XYZ(s)
    else
        x = 0.0
        y = 0.0
        z = 0.0
        for i in 1:nSpectralSamples
            x += XXX[i] * s[i]
            y += YYY[i] * s[i]
            z += ZZZ[i] * s[i]
        end
        scale = (sampledLambdaEnd - sampledLambdaStart) / (CIE_Y_integral * nSpectralSamples)
        x *= scale
        y *= scale
        z *= scale
        return XYZPBRT(x, y, z)
    end
end

function make_spectral_constants()::Tuple{Spectrum, Spectrum, Spectrum, Spectrum, Spectrum, Spectrum, Spectrum, Spectrum, Spectrum, Spectrum, Spectrum, Spectrum, Spectrum, Spectrum, Spectrum, Spectrum, Spectrum}
    tmp_X = zeros(nSpectralSamples)
    tmp_Y = zeros(nSpectralSamples)
    tmp_Z = zeros(nSpectralSamples)
    tmp_rgbRefl2SpectWhite = zeros(nSpectralSamples)
    tmp_rgbRefl2SpectCyan = zeros(nSpectralSamples)
    tmp_rgbRefl2SpectMagenta = zeros(nSpectralSamples)
    tmp_rgbRefl2SpectYellow = zeros(nSpectralSamples)
    tmp_rgbRefl2SpectRed = zeros(nSpectralSamples)
    tmp_rgbRefl2SpectGreen = zeros(nSpectralSamples)
    tmp_rgbRefl2SpectBlue = zeros(nSpectralSamples)
    tmp_rgbIllum2SpectWhite = zeros(nSpectralSamples)
    tmp_rgbIllum2SpectCyan = zeros(nSpectralSamples)
    tmp_rgbIllum2SpectMagenta = zeros(nSpectralSamples)
    tmp_rgbIllum2SpectYellow = zeros(nSpectralSamples)
    tmp_rgbIllum2SpectRed = zeros(nSpectralSamples)
    tmp_rgbIllum2SpectGreen = zeros(nSpectralSamples)
    tmp_rgbIllum2SpectBlue = zeros(nSpectralSamples)
    for i in 1:nSpectralSamples
        wl0 = lerp((i-1) / nSpectralSamples, Float64(sampledLambdaStart), Float64(sampledLambdaEnd))
        wl1 = lerp(i / nSpectralSamples, Float64(sampledLambdaStart), Float64(sampledLambdaEnd))
        tmp_X[i] = average_spectrum_samples(CIE_lambda, CIE_X, nCIESamples, wl0, wl1)
        tmp_Y[i] = average_spectrum_samples(CIE_lambda, CIE_Y, nCIESamples, wl0, wl1)
        tmp_Z[i] = average_spectrum_samples(CIE_lambda, CIE_Z, nCIESamples, wl0, wl1)

        tmp_rgbRefl2SpectWhite[i] =    average_spectrum_samples(RGB2SpectLambda, RGBRefl2SpectWhite, nRGB2SpectSamples, wl0, wl1)
        tmp_rgbRefl2SpectCyan[i] =     average_spectrum_samples(RGB2SpectLambda, RGBRefl2SpectCyan, nRGB2SpectSamples, wl0, wl1)
        tmp_rgbRefl2SpectMagenta[i] =  average_spectrum_samples(RGB2SpectLambda, RGBRefl2SpectMagenta, nRGB2SpectSamples, wl0, wl1)
        tmp_rgbRefl2SpectYellow[i] =   average_spectrum_samples(RGB2SpectLambda, RGBRefl2SpectYellow, nRGB2SpectSamples, wl0, wl1)
        tmp_rgbRefl2SpectRed[i] =      average_spectrum_samples(RGB2SpectLambda, RGBRefl2SpectRed, nRGB2SpectSamples, wl0, wl1)
        tmp_rgbRefl2SpectGreen[i] =    average_spectrum_samples(RGB2SpectLambda, RGBRefl2SpectGreen, nRGB2SpectSamples, wl0, wl1)
        tmp_rgbRefl2SpectBlue[i] =     average_spectrum_samples(RGB2SpectLambda, RGBRefl2SpectBlue, nRGB2SpectSamples, wl0, wl1)
        tmp_rgbIllum2SpectWhite[i] =   average_spectrum_samples(RGB2SpectLambda, RGBIllum2SpectWhite, nRGB2SpectSamples, wl0, wl1)
        tmp_rgbIllum2SpectCyan[i] =    average_spectrum_samples(RGB2SpectLambda, RGBIllum2SpectCyan, nRGB2SpectSamples, wl0, wl1)
        tmp_rgbIllum2SpectMagenta[i] = average_spectrum_samples(RGB2SpectLambda, RGBIllum2SpectMagenta, nRGB2SpectSamples, wl0, wl1)
        tmp_rgbIllum2SpectYellow[i] =  average_spectrum_samples(RGB2SpectLambda, RGBIllum2SpectYellow, nRGB2SpectSamples, wl0, wl1)
        tmp_rgbIllum2SpectRed[i] =     average_spectrum_samples(RGB2SpectLambda, RGBIllum2SpectRed, nRGB2SpectSamples, wl0, wl1)
        tmp_rgbIllum2SpectGreen[i] =   average_spectrum_samples(RGB2SpectLambda, RGBIllum2SpectGreen, nRGB2SpectSamples, wl0, wl1)
        tmp_rgbIllum2SpectBlue[i] =    average_spectrum_samples(RGB2SpectLambda, RGBIllum2SpectBlue, nRGB2SpectSamples, wl0, wl1)
    end
    return Spectrum(tmp_X), Spectrum(tmp_Y), Spectrum(tmp_Z), Spectrum(tmp_rgbRefl2SpectWhite), Spectrum(tmp_rgbRefl2SpectCyan), Spectrum(tmp_rgbRefl2SpectMagenta), Spectrum(tmp_rgbRefl2SpectYellow), Spectrum(tmp_rgbRefl2SpectRed), Spectrum(tmp_rgbRefl2SpectGreen), Spectrum(tmp_rgbRefl2SpectBlue), Spectrum(tmp_rgbIllum2SpectWhite), Spectrum(tmp_rgbIllum2SpectCyan), Spectrum(tmp_rgbIllum2SpectMagenta), Spectrum(tmp_rgbIllum2SpectYellow), Spectrum(tmp_rgbIllum2SpectRed), Spectrum(tmp_rgbIllum2SpectGreen), Spectrum(tmp_rgbIllum2SpectBlue)
end

function y_spectrum(s::Spectrum)::Float64
    if length(s) == 3
        return s.a * 0.212671 + s.b * 0.715160 + s.c * 0.072169
    else
        yy = 0.0
        for i in 1:nSpectralSamples
            yy += YYY[i] * s[i]
        end
        return yy * (sampledLambdaEnd - sampledLambdaStart) / (CIE_Y_integral * nSpectralSamples)
    end
end
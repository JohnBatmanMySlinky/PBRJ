
function spectrum_from_sampled(lambda::Vector{Float64}, v::Vector{Float64}, n::Int64)::Spectrum
    # aight so (λ_i, v_i) will be at some frequency
    # and this converts that to what ever nSpectralSamples is

    # check lambda is sorted
    @assert check_monotonic(lambda)

    tmp = zeroes(nSpectralSamples)
    for i in 1:nSpectralSamples
        lambda0 = lerp(i/nSpectralSamples, sampledLambdaStart, sampledLambdaEnd)
        lambda1 = lerp((i+1)/nSpectralSamples, sampledLambdaStart, sampledLambdaEnd)
        tmp[i] = average_spectrum_samples(lambda, v, n, lambda0, lambda1)
    end
    return Spectrum(tmp)
end

function spectrum_from_RGB(r::Float64, g::Float64, b::Float64)::Spectrum
    if true # JOHN HACK
        # Convert reflectance spectrum to RGB
        if (r <= g) && (r <= b)
            # Compute reflectance _SampledSpectrum_ with r as minimum
            s = Spectrum(r * rgbRefl2SpectWhite)
            if g <= b
                s = s + (g - r) * rgbRefl2SpectCyan
                s = s + (b - g) * rgbRefl2SpectBlue
            else
                s = s + (b - r) * rgbRefl2SpectCyan
                s = s + (g - b) * rgbRefl2SpectGreen
            end
        elseif (g <= r) && (g <= b)
            # Compute reflectance _SampledSpectrum_ with g as minimum
            s = Spectrum(g * rgbRefl2SpectWhite)
            if r <= b
                s = s + (r - b) * rgbRefl2SpectMagenta
                s = s + (b - r) * rgbRefl2SpectBlue
            else
                s = s + (b - g) * rgbRefl2SpectMagenta
                s = s + (r - b) * rgbRefl2SpectRed
            end
        else
            # Compute reflectance _SampledSpectrum_ with b as minimum
            s = Spectrum(b * rgbRefl2SpectWhite)
            if r <= g
                s = s + (r - b) * rgbRefl2SpectYellow
                s = s + (g - r) * rgbRefl2SpectGreen
            else
                s = s + (g - b) * rgbRefl2SpectYellow
                s = s + (r - g) * rgbRefl2SpectRed
            end
        end
        s = s * 0.94
    else
        # Convert illuminant spectrum to RGB
        if (r <= g) && (r <= b)
            # Compute illuminant _SampledSpectrum_ with r as minimum
            s = Spectrum(r * rgbIllum2SpectWhite)
            if g <= b
                s = s + (g - r) * rgbIllum2SpectCyan
                s = s + (b - g) * rgbIllum2SpectBlue
            else
                s = s + (b - r) * rgbIllum2SpectCyan
                s = s + (g - b) * rgbIllum2SpectGreen
            end
        elseif (g <= r) && (g <= b)
            # Compute illuminant _SampledSpectrum_ with g as minimum
            s = Spectrum(g * rgbIllum2SpectWhite)
            if r <= b
                s = s + (r - g) * rgbIllum2SpectMagenta
                s = s + (b - r) * rgbIllum2SpectBlue
            else
                s = s + (b - g) * rgbIllum2SpectMagenta
                s = s + (r - b) * rgbIllum2SpectRed
            end
        else
            # Compute illuminant _SampledSpectrum_ with b as minimum
            s = Spectrum(b * rgbIllum2SpectWhite)
            if r <= g
                s = s + (r - b) * rgbIllum2SpectYellow
                s = s + (g - r) * rgbIllum2SpectGreen
            else
                s = s + (g - b) * rgbIllum2SpectYellow
                s = s + (r - g) * rgbIllum2SpectRed
            end
        end
        s = s * .86445
    end
    return clamp.(s, 0.0, 1.0)
end

# THE ENTRY POINT
function spectrum_from_float(r::Float64, g::Float64, b::Float64)::Spectrum
    if nSpectralSamples == 3
        return Spectrum(r,g,b)
    else
        return spectrum_from_RGB(r, g, b)
    end
end

function spectrum_from_float(x::Float64)::Spectrum
    return spectrum_from_float(x, x, x)
end
function blackbody(lambda::Vector{Float64}, T::Float64)
    n = length(lambda)
    LL = zeros(Float64, n)
    if T < 0.0
        return LL
    end
    c = 299792458.0
    h = 6.62606957e-34
    kb = 1.3806488e-23
    for i in 1:n
        # Compute emitted radiance for blackbody at wavelength _lambda[i]_
        l = lambda[i] * 1e-9
        LL[i] = (2 * h * c^2) / (l^5 * (exp((h * c) / (l * kb *T)) - 1))
    end
    return LL
end

function spectrum_from_sampled(lambda::Vector{Float64}, v::Vector{Float64}, n::Int64)::Spectrum
    # aight so (λ_i, v_i) will be at some frequency
    # and this converts that to what ever nSpectralSamples is

    # check lambda is sorted
    @assert check_monotonic(lambda)
    @assert length(lambda) == length(v) == n

    if nSpectralSamples == 3
        x = 0
        y = 0
        z = 0
        for i in 0:(nCIESamples-1)
            val = interpolate_spectrum_samples(lambda, v, CIE_lambda[i+1])
            x += val * CIE_X[i+1]
            y += val * CIE_Y[i+1]
            z += val * CIE_Z[i+1]
        end
        scale = Float64(CIE_lambda[nCIESamples - 1 + 1] - CIE_lambda[0+1]) / Float64(CIE_Y_integral * nCIESamples)
        x *= scale
        y *= scale
        z *= scale
        @info "BUILDING SPECTRUM: $(XYZ_to_RGB(XYZPBRT(x, y, z)))"
        return XYZ_to_RGB(XYZPBRT(x, y, z))
    else
        tmp = zeros(nSpectralSamples)
        for i in 1:nSpectralSamples
            lambda0 = lerp(i/nSpectralSamples, Float64(sampledLambdaStart), Float64(sampledLambdaEnd))
            lambda1 = lerp((i+1)/nSpectralSamples, Float64(sampledLambdaStart), Float64(sampledLambdaEnd))
            tmp[i] = average_spectrum_samples(lambda, v, n, lambda0, lambda1)
            @info "BUILDING SPECTRUM: $lambda0 - $lambda1 == $(tmp[i])"
        end
        return Spectrum(tmp)
    end
end

#thank god for ChatGPT
function interpolate_spectrum_samples(lambda::Vector{Float64}, vals::Vector{Float64}, l::Float64)
    # Check that lambda values are strictly increasing
    @assert all(diff(lambda) .> 0) "Wavelengths must be strictly increasing"
    
    # Handle edge cases
    if l <= lambda[1]
        return vals[1]
    elseif l >= lambda[end]
        return vals[end]
    end
    
    # Find the interval containing l using searchsorted
    # This is equivalent to the FindInterval function in the original code
    offset = searchsorted(lambda, l).start - 1
    
    # Verify l is in the correct interval
    @assert l >= lambda[offset] && l <= lambda[offset + 1] "Interpolation value out of bounds"
    
    # Calculate interpolation parameter t
    t = (l - lambda[offset]) / (lambda[offset + 1] - lambda[offset])
    
    # Perform linear interpolation (Lerp)
    return (1 - t) * vals[offset] + t * vals[offset + 1]
end

function spectrum_from_sampled(spd_path::String)::Spectrum
    # reads SPD data from spd file
    lambda = Float64[]
    v = Float64[]
    open(spd_path) do file
        for line in eachline(file)
            vals = split(line)
            push!(lambda, parse(Float64, vals[1]))
            push!(v, parse(Float64, vals[2]))
        end
    end
    
    return spectrum_from_sampled(lambda, v, length(lambda))
end

function spectrum_from_RGB(r::Float64, g::Float64, b::Float64, spectrum_type::Type{S}=Reflectance)::Spectrum where S <: SpectrumType
    if spectrum_type == Reflectance
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
    return s
end

# THE ENTRY POINT
function spectrum_from_float(r::Float64, g::Float64, b::Float64, spectrum_type::Type{S}=Reflectance)::Spectrum where S <: SpectrumType
    if nSpectralSamples == 3
        return Spectrum(r,g,b)
    else
        return spectrum_from_RGB(r, g, b, spectrum_type)
    end
end

function spectrum_from_float(x::Float64, spectrum_type::Type{S}=Reflectance)::Spectrum where S <: SpectrumType
    return spectrum_from_float(x, x, x, spectrum_type)
end
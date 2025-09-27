function read_image(texmap::String)::Tuple{Vector{RayTracing.Spectrum}, Int64, Int64}
    ident = texmap[end-3:end]
    if ident == ".exr"
        dat = OpenEXR.load(texmap)
    elseif ident == ".jpg"
        dat = FileIO.load(texmap)
    elseif ident == ".png"
        dat = FileIO.load(texmap)
    else
        @assert false # NOT IMPLEMENTED
    end
    
    # Convert from colors to Spectrum and adjust by LL
    L, W = size(dat)
    dat2 = zeros(Spectrum, L * W)
    i = 0
    
    for l in 1:L
        for w in 1:W
            i += 1
            pixel = dat[l, w]
            
            # Handle both grayscale and color pixels
            if pixel isa Gray
                # For grayscale, use the same value for all RGB channels
                gray_val = Float64(pixel.val)
                dat2[i] = spectrum_from_float(gray_val, gray_val, gray_val)
            else
                # For color pixels (RGB, RGBA, etc.)
                dat2[i] = spectrum_from_float(Float64(pixel.r), Float64(pixel.g), Float64(pixel.b))
            end
        end
    end
    
    return dat2, L, W
end

function convert_in_to_spectrum(value::Spectrum, scale::Float64, do_gamma::Bool)::Spectrum
    if do_gamma
        return scale * inverse_gamma_correct.(value)
    else
        return scale .* value
    end
end

function convert_in_to_float(value::Spectrum, scale::Float64, do_gamma::Bool)::Float64
    new_value = y_spectrum(value)
    if do_gamma
        return scale * inverse_gamma_correct(new_value)
    else
        return scale * new_value
    end
end

function inverse_gamma_correct(value::Float64)::Float64
    if value <= 0.04045
        return value / 12.92
    else
        return ((value + 0.055) / 1.055) ^ 2.4
    end
end

function gamma_correct(value::RGB{Float64})::RGB{Float64}
    return RGB{Float64}(gamma_correct(value.r), gamma_correct(value.g), gamma_correct(value.b))
end

function gamma_correct(value::Float64)::Float64
    return value
    # if value <= 0.0031308
    #     return 12.92 * value
    # end
    # return 1.055 * value ^ (1 / 2.4) - 0.055
end
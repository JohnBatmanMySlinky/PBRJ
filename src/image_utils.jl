function read_image(texmap::String, LL::Union{Float64, RayTracing.Spectrum}, do_gamma::Bool)::Tuple{Vector{RayTracing.Spectrum}, Int64, Int64}
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
                tmp_val = Spectrum(gray_val, gray_val, gray_val)
                dat2[i] = do_gamma ? LL * inverse_gamma_correct.(tmp_val) : LL * tmp_val
            else
                # For color pixels (RGB, RGBA, etc.)
                tmp_val = Spectrum(pixel.r, pixel.g, pixel.b) * LL
                dat2[i] = do_gamma ? LL * inverse_gamma_correct.(tmp_val) : LL * tmp_val
            end
        end
    end
    
    return dat2, L, W
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
    if value <= 0.0031308
        return 12.92 * value
    end
    return 1.055 * value ^ (1 / 2.4) - 0.055
end
function read_image(texmap::String, LL::Union{Float64, RayTracing.Spectrum})::Tuple{Vector{RayTracing.Spectrum}, Int64, Int64}
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
                dat2[i] = Spectrum(gray_val, gray_val, gray_val) * LL
            else
                # For color pixels (RGB, RGBA, etc.)
                dat2[i] = Spectrum(pixel.r, pixel.g, pixel.b) * LL
            end
        end
    end
    
    return dat2, L, W
end
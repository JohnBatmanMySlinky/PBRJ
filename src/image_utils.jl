function read_image(texmap::String)
    ident = texmap[end-3:end]
    if ident == ".exr"
        dat = OpenEXR.load(texmap)
        L, W = size(dat)
        dat2 = Vector{RGB{Float32}}(undef, L * W)
        i = 0
        for l in 1:L
            for w in 1:W
                i += 1
                pixel = dat[l, w]
                if pixel isa Gray
                    v = Float32(pixel.val)
                    dat2[i] = RGB{Float32}(v, v, v)
                else
                    dat2[i] = RGB{Float32}(Float32(pixel.r), Float32(pixel.g), Float32(pixel.b))
                end
            end
        end
        return dat2, L, W
    elseif (ident == ".jpg") || ident == "jpeg" || ident == ".png"
        dat = FileIO.load(texmap)
        L, W = size(dat)
        dat2 = Vector{NTuple{3, UInt8}}(undef, L * W)
        i = 0
        for l in 1:L
            for w in 1:W
                i += 1
                pixel = dat[l, w]
                if pixel isa Gray
                    v = round(UInt8, clamp(Float64(pixel.val) * 255.0, 0.0, 255.0))
                    dat2[i] = (v, v, v)
                else
                    r = round(UInt8, clamp(Float64(pixel.r) * 255.0, 0.0, 255.0))
                    g = round(UInt8, clamp(Float64(pixel.g) * 255.0, 0.0, 255.0))
                    b = round(UInt8, clamp(Float64(pixel.b) * 255.0, 0.0, 255.0))
                    dat2[i] = (r, g, b)
                end
            end
        end
        return dat2, L, W
    else
        @assert false # NOT IMPLEMENTED
    end
end

# Store as RGB{Float32} — conversion to Spectrum happens at lookup time in ImageTexture
function convert_in_to_spectrum(pixel::RGB{Float32}, scale::Float64, do_gamma::Bool)::SVector{3, Float32}
    r, g, b = Float64(pixel.r), Float64(pixel.g), Float64(pixel.b)
    if do_gamma
        r, g, b = inverse_gamma_correct(r), inverse_gamma_correct(g), inverse_gamma_correct(b)
    end
    return SVector{3, Float32}(Float32(scale * r), Float32(scale * g), Float32(scale * b))
end

function convert_in_to_spectrum(pixel::NTuple{3, UInt8}, scale::Float64, do_gamma::Bool)::SVector{3, Float16}
    r, g, b = Float64(pixel[1]) / 255.0, Float64(pixel[2]) / 255.0, Float64(pixel[3]) / 255.0
    if do_gamma
        r, g, b = inverse_gamma_correct(r), inverse_gamma_correct(g), inverse_gamma_correct(b)
    end
    return SVector{3, Float16}(Float16(scale * r), Float16(scale * g), Float16(scale * b))
end

# Store as Float32 — conversion to Float64 happens at lookup time in ImageTexture
function convert_in_to_float(pixel::RGB{Float32}, scale::Float64, do_gamma::Bool)::Float32
    val = 0.2126 * Float64(pixel.r) + 0.7152 * Float64(pixel.g) + 0.0722 * Float64(pixel.b)
    if do_gamma; val = inverse_gamma_correct(val); end
    return Float32(scale * val)
end

function convert_in_to_float(pixel::NTuple{3, UInt8}, scale::Float64, do_gamma::Bool)::Float16
    val = (0.2126 * Float64(pixel[1]) + 0.7152 * Float64(pixel[2]) + 0.0722 * Float64(pixel[3])) / 255.0
    if do_gamma; val = inverse_gamma_correct(val); end
    return Float16(scale * val)
end

function read_image_as_spectrum(texmap::String)::Tuple{Vector{Spectrum}, Int64, Int64}
    raw, L, W = read_image(texmap)
    spectra = Vector{Spectrum}(undef, L * W)
    for i in 1:L*W
        pixel = raw[i]
        if pixel isa RGB{Float32}
            spectra[i] = spectrum_from_float(Float64(pixel.r), Float64(pixel.g), Float64(pixel.b))
        else  # NTuple{3, UInt8}
            spectra[i] = spectrum_from_float(Float64(pixel[1]) / 255.0, Float64(pixel[2]) / 255.0, Float64(pixel[3]) / 255.0)
        end
    end
    return spectra, L, W
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
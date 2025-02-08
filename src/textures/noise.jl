# thanks https://rosettacode.org/wiki/Perlin_noise#Julia

struct Noise <: Texture
    scale::Float64
end

# Perlin Noise Data
const NoisePermSize = 256
const NoisePerm = Int64[
    151, 160, 137, 91, 90, 15, 131, 13, 201, 95, 96, 53, 194, 233, 7, 225, 140, 36, 103,
    30, 69, 142, 8, 99, 37, 240, 21, 10, 23, 190, 6, 148, 247, 120, 234, 75, 0, 26, 197,
    62, 94, 252, 219, 203, 117, 35, 11, 32, 57, 177, 33, 88, 237, 149, 56, 87, 174, 20,
    125, 136, 171, 168, 68, 175, 74, 165, 71, 134, 139, 48, 27, 166, 77, 146, 158, 231,
    83, 111, 229, 122, 60, 211, 133, 230, 220, 105, 92, 41, 55, 46, 245, 40, 244, 102,
    143, 54, 65, 25, 63, 161, 1, 216, 80, 73, 209, 76, 132, 187, 208, 89, 18, 169, 200,
    196, 135, 130, 116, 188, 159, 86, 164, 100, 109, 198, 173, 186, 3, 64, 52, 217, 226,
    250, 124, 123, 5, 202, 38, 147, 118, 126, 255, 82, 85, 212, 207, 206, 59, 227, 47,
    16, 58, 17, 182, 189, 28, 42, 223, 183, 170, 213, 119, 248, 152, 2, 44, 154, 163,
    70, 221, 153, 101, 155, 167, 43, 172, 9, 129, 22, 39, 253, 19, 98, 108, 110, 79,
    113, 224, 232, 178, 185, 112, 104, 218, 246, 97, 228, 251, 34, 242, 193, 238, 210,
    144, 12, 191, 179, 162, 241, 81, 51, 145, 235, 249, 14, 239, 107, 49, 192, 214, 31,
    181, 199, 106, 157, 184, 84, 204, 176, 115, 121, 50, 45, 127, 4, 150, 254, 138, 236,
    205, 93, 222, 114, 67, 29, 24, 72, 243, 141, 128, 195, 78, 66, 215, 61, 156, 180, 

    151, 160, 137, 91, 90, 15, 131, 13, 201, 95, 96, 53, 194, 233, 7, 225, 140, 36, 103,
    30, 69, 142, 8, 99, 37, 240, 21, 10, 23, 190, 6, 148, 247, 120, 234, 75, 0, 26, 197,
    62, 94, 252, 219, 203, 117, 35, 11, 32, 57, 177, 33, 88, 237, 149, 56, 87, 174, 20,
    125, 136, 171, 168, 68, 175, 74, 165, 71, 134, 139, 48, 27, 166, 77, 146, 158, 231,
    83, 111, 229, 122, 60, 211, 133, 230, 220, 105, 92, 41, 55, 46, 245, 40, 244, 102,
    143, 54, 65, 25, 63, 161, 1, 216, 80, 73, 209, 76, 132, 187, 208, 89, 18, 169, 200,
    196, 135, 130, 116, 188, 159, 86, 164, 100, 109, 198, 173, 186, 3, 64, 52, 217, 226,
    250, 124, 123, 5, 202, 38, 147, 118, 126, 255, 82, 85, 212, 207, 206, 59, 227, 47,
    16, 58, 17, 182, 189, 28, 42, 223, 183, 170, 213, 119, 248, 152, 2, 44, 154, 163,
    70, 221, 153, 101, 155, 167, 43, 172, 9, 129, 22, 39, 253, 19, 98, 108, 110, 79,
    113, 224, 232, 178, 185, 112, 104, 218, 246, 97, 228, 251, 34, 242, 193, 238, 210,
    144, 12, 191, 179, 162, 241, 81, 51, 145, 235, 249, 14, 239, 107, 49, 192, 214, 31,
    181, 199, 106, 157, 184, 84, 204, 176, 115, 121, 50, 45, 127, 4, 150, 254, 138, 236,
    205, 93, 222, 114, 67, 29, 24, 72, 243, 141, 128, 195, 78, 66, 215, 61, 156, 180
]

# Helper functions
function grad(x::Int64, y::Int64, z::Int64, dx::Float64, dy::Float64, dz::Float64)
    h = NoisePerm[NoisePerm[NoisePerm[x+1] + y+1] + z+1] & 15
    u = (h < 8 || h == 12 || h == 13) ? dx : dy
    v = (h < 4 || h == 12 || h == 13) ? dy : dz
    return ((h & 1) == 0 ? u : -u) + ((h & 2) == 0 ? v : -v)
end

function noise_weight(t::Float64)
    # 6t^5 - 15t^4 + 10t^3
    return 6 * t^5 - 15 * t^4 + 10 * t^3
end

function lerp(t::Float64, v1::Float64, v2::Float64)
    return v1 + t * (v2 - v1)
end

# Main noise functions
function noise(x::Float64, y::Float64, z::Float64)
    # Handle large coordinates
    x = mod(x, Float64(1 << 30))
    y = mod(y, Float64(1 << 30))
    z = mod(z, Float64(1 << 30))
    
    ix = floor(Int, x)
    iy = floor(Int, y)
    iz = floor(Int, z)
    dx = x - ix
    dy = y - iy
    dz = z - iz

    # Compute gradient weights
    ix = ix & (NoisePermSize - 1)
    iy = iy & (NoisePermSize - 1)
    iz = iz & (NoisePermSize - 1)
    
    w000 = grad(ix, iy, iz, dx, dy, dz)
    w100 = grad(ix + 1, iy, iz, dx - 1, dy, dz)
    w010 = grad(ix, iy + 1, iz, dx, dy - 1, dz)
    w110 = grad(ix + 1, iy + 1, iz, dx - 1, dy - 1, dz)
    w001 = grad(ix, iy, iz + 1, dx, dy, dz - 1)
    w101 = grad(ix + 1, iy, iz + 1, dx - 1, dy, dz - 1)
    w011 = grad(ix, iy + 1, iz + 1, dx, dy - 1, dz - 1)
    w111 = grad(ix + 1, iy + 1, iz + 1, dx - 1, dy - 1, dz - 1)

    # Compute trilinear interpolation
    wx = noise_weight(dx)
    wy = noise_weight(dy)
    wz = noise_weight(dz)
    
    x00 = lerp(wx, w000, w100)
    x10 = lerp(wx, w010, w110)
    x01 = lerp(wx, w001, w101)
    x11 = lerp(wx, w011, w111)
    y0 = lerp(wy, x00, x10)
    y1 = lerp(wy, x01, x11)
    
    return lerp(wz, y0, y1)
end

function noise(p::Pnt3)
    return noise(p.x, p.y, p.z)
end

function dnoise(p::Pnt3)::Pnt3
    delta = 0.01
    n = noise(p)
    noiseDelta = Pnt3(
        noise(p + Pnt3(delta, 0.0, 0.0)),
        noise(p + Pnt3(0.0, delta, 0.0)),
        noise(p + Pnt3(0.0, 0.0, delta))
    )
    return (noiseDelta .- n) ./ delta
end

function fbm(p::Pnt3, dpdx::Vec3, dpdy::Vec3, omega::Float64, maxOctaves::Int)
    # Compute number of octaves for antialiased FBm
    len2 = max(dot(dpdx, dpdx), dot(dpdy, dpdy))
    n = clamp(-1 - log2(len2) / 2, 0, maxOctaves)
    nInt = floor(Int, n)

    # Compute sum of octaves of noise for FBm
    sum = 0.0
    lambda = 1.0
    o = 1.0
    
    for i in 0:nInt-1
        sum += o * noise(lambda * p)
        lambda *= 1.99
        o *= omega
    end
    
    nPartial = n - nInt
    sum += o * smoothstep(nPartial, 0.3, 0.7) * noise(lambda * p)
    
    return sum
end

function turbulence(p::Pnt3, dpdx::Vec3, dpdy::Vec3, omegaFloat6464, maxOctaves::Int)
    # Compute number of octaves for antialiased FBm
    len2 = max(dot(dpdx, dpdx), dot(dpdy, dpdy))
    n = clamp(-1 - log2(len2) / 2, 0, maxOctaves)
    nInt = floor(Int, n)

    # Compute sum of octaves of noise for turbulence
    sum = 0.0
    lambda = 1.0
    o = 1.0
    
    for i in 0:nInt-1
        sum += o * abs(noise(lambda * p))
        lambda *= 1.99
        o *= omega
    end

    # Account for contributions of clamped octaves
    nPartial = n - nInt
    sum += o * lerp(smoothstep(nPartial, 0.3, 0.7), 0.2, abs(noise(lambda * p)))
    
    for i in nInt:maxOctaves-1
        sum += o * 0.2
        o *= omega
    end
    
    return sum
end

# Helper functions for smoothstep and interpolation
function smoothstep(edge0::Float64, edge1::Float64, x::Float64)
    t = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)
end

function smoothstep(x::Float64, edge0::Float64, edge1::Float64)
    return smoothstep(edge0, edge1, x)
end
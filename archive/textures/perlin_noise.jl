# thanks https://rosettacode.org/wiki/Perlin_noise#Julia

struct PerlinNoise <: Texture
    scale::Float64
end

const permutation = UInt8[
    151, 160, 137, 91, 90, 15, 131, 13, 201, 95, 96, 53, 194, 233,
    7, 225, 140, 36, 103, 30, 69, 142, 8, 99, 37, 240, 21, 10, 23,
    190, 6, 148, 247, 120, 234, 75, 0, 26, 197, 62, 94, 252, 219,
    203, 117, 35, 11, 32, 57, 177, 33, 88, 237, 149, 56, 87, 174,
    20, 125, 136, 171, 168, 68, 175, 74, 165, 71, 134, 139, 48, 27,
    166, 77, 146, 158, 231, 83, 111, 229, 122, 60, 211, 133, 230,
    220, 105, 92, 41, 55, 46, 245, 40, 244, 102, 143, 54, 65, 25,
    63, 161, 1, 216, 80, 73, 209, 76, 132, 187, 208, 89, 18, 169,
    200, 196, 135, 130, 116, 188, 159, 86, 164, 100, 109, 198, 173,
    186, 3, 64, 52, 217, 226, 250, 124, 123, 5, 202, 38, 147, 118,
    126, 255, 82, 85, 212, 207, 206, 59, 227, 47, 16, 58, 17, 182,
    189, 28, 42, 223, 183, 170, 213, 119, 248, 152, 2, 44, 154, 163,
    70, 221, 153, 101, 155, 167,  43, 172, 9, 129, 22, 39, 253, 19,
    98, 108, 110, 79, 113, 224, 232, 178, 185,  112, 104, 218, 246,
    97, 228, 251, 34, 242, 193, 238, 210, 144, 12, 191, 179, 162,
    241, 81, 51, 145, 235, 249, 14, 239, 107, 49, 192, 214, 31, 181,
    199, 106, 157, 184, 84, 204, 176, 115, 121, 50, 45, 127, 4, 150,
    254, 138, 236, 205, 93, 222,    114, 67, 29, 24, 72, 243, 141,
    128, 195, 78, 66, 215, 61, 156, 180]

function grad(h::UInt8, x::Float64, y::Float64, z::Float64)::Float64
    h &= 15                                                 # CONVERT LO 4 BITS OF HASH CODE
    u = h < 8 ? x : y                                       # INTO 12 GRADIENT DIRECTIONS.
    v = h < 4 ? y : h == 12 || h == 14 ? x : z
    (h & 1 == 0 ? u : -u) + (h & 2 == 0 ? v : -v)
end
function smoothstep(x::Float64)::Float64
    return 3x^2 - 2x^3
end
function lerp(t::Float64, a::Float64, b::Float64)::Float64
    return a + t * (b - a)
end
function floorb(x::Float64)::UInt8
    return Int(floor(x)) & 0xff
end
function perlin_noise(p::Vec3)::Float64
    #verbose as fuck
    perms = vcat(permutation, permutation)
    X, Y, Z = floorb(p[1]), floorb(p[2]), floorb(p[3])                      # defining unit cube
    x, y, z = p[1] - floor(p[1]), p[2] - floor(p[2]), p[3] - floor(p[3])    # relative x,y,z within unit cube
    u, v, w = smoothstep(x), smoothstep(y), smoothstep(z)                   # smoothstep'd relative x,y,z
    A = perms[X + 1] + Y; AA = perms[A + 1] + Z; AB = perms[A + 2] + Z
    B = perms[X + 2] + Y; BA = perms[B + 1] + Z; BB = perms[B + 2] + Z      # hash coords of 8 corners of cube

    # gradients at the 8 corners
    g1 = grad(perms[AA+1], x,   y,   z  )
    g2 = grad(perms[BA+1], x-1, y,   z  )
    g3 = grad(perms[AB+1], x,   y-1, z  )
    g4 = grad(perms[BB+1], x-1, y-1, z  )
    g5 = grad(perms[AA+2], x,   y,   z-1)
    g6 = grad(perms[BA+2], x-1, y,   z-1)
    g7 = grad(perms[AB+2], x,   y-1, z-1)
    g8 = grad(perms[BB+2], x-1, y-1, z-1)

    # trilinear interpolation
    u1 = lerp(u, g1, g2)
    u2 = lerp(u, g3, g4)
    u3 = lerp(u, g5, g6)
    u4 = lerp(u, g7, g8)
    v1 = lerp(v, u1, u2)
    v2 = lerp(v, u3, u4)
    w1 = lerp(w, v1, v2)
    return w1
end

function color_value(pn::PerlinNoise, u::Float64, v::Float64, p::Vec3)::Vec3
    noise = (perlin_noise(p ./ pn.scale)+1)/2
    if sqrt(noise) < .75
        return Vec3(0, 0, 0)
    else
        return Vec3(noise, noise, noise) .* 5
    end
end
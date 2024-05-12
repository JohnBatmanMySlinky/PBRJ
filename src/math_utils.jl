function safe_sqrt(x::Float64)::Float64
    # JOHN HACK
    # @assert x > -1e-3 # not too negative
    return sqrt(max(0.0, x))
end

function solve_quadratic(a::Float64, b::Float64, c::Float64)::Tuple{Bool, Float64, Float64}
    # Find disriminant.
    d = b ^ 2 - 4 * a * c
    if d < 0
        return false, typemax(Float64), typemax(Float64)
    end
    d = d |> sqrt
    # Compute roots.
    q = -0.5 * (b + (b < 0 ? -d : d))
    t0 = q / a
    t1 = c / q
    if t0 > t1
        t0, t1 = t1, t0
    end
    return true, t0, t1
end

function distance(p1::Pnt3, p2::Pnt3)::Float64
    return norm(p1 - p2)
end

function distance_squared(p1::Pnt3, p2::Pnt3)::Float64
    p = p1 - p2
    return dot(p, p)
end

function length_squared(v::Vec3)::Float64
    return sum(v.^2)
end

function length_pbrt(v::Vec3)::Float64
    return sqrt(length_squared(v))
end

# Equivalent to std::acos(Dot(a, b)), but more numerically stable.
# via http://www.plunk.org/~hatch/rightway.html
function angle_between(v1::Vec3, v2::Vec3)::Float64
    if dot(v1, v2) < 0.0
        return pi - 2.0 * safe_asin(length_pbrt(v1 + v2) / 2.0)
    else
        return 2.0 * safe_asin(length_pbrt(v2 - v1) / 2.0)
    end
end

function safe_asin(f::Float64)::Float64
    return asin(clamp(f, -1.0, 1.0))
end

function difference_of_products(a::Float64, b::Float64, c::Float64, d::Float64)::Float64
    # JOHN HACK
    # this is clearly just me porting their code over needlessly exactly.
    cd = c * d
    dop = a * b - cd
    err = -c * d + cd
    return dop + err
end

function sum_of_products(a::Float64, b::Float64, c::Float64, d::Float64)::Float64
    cd = c * d
    sop = a * b + cd
    err = c * d - cd
    return sop + err
end

function gram_schmidt(v::Vec3, w::Vec3)::Vec3
    return v - dot(v, w) * w
end

function lerp(t::Float64, a::Float64, b::Float64)::Float64
    return a + t * (b - a)
end

function spherical_phi(v::Vec3)::Float64
    p = atan(v.y, v.x)
    return p < 0 ? (p + 2 * pi) : p
end

function spherical_theta(v::Vec3)::Float64
    return acos(clamp(v.z, -1.0, 1.0))
end

function spherical_direction(sin_theta::Float64, cos_theta::Float64, phi::Float64, x::Vec3, y::Vec3, z::Vec3)::Vec3
    return sin_theta * cos(phi) * x + sin_theta * sin(phi) * y + cos_theta * z
end

function orthonormal_basis(v::Vec3)::Tuple{Vec3, Vec3, Vec3}
    if abs(v.x) > abs(v.y)
        v2 = Vec3(-v.z, 0.0, v.x) / sqrt(v.x^2 + v.z^2)
    else
        v2 = Vec3(0.0, v.z, -v.y) / sqrt(v.y^2 + v.z^2)
    end
    return v, v2, cross(v, v2)
end

# for implicit surface normal reverse engineering
function orthonormal_basis(v::Nml3)::Tuple{Nml3, Vec3, Vec3}
    if abs(v.x) > abs(v.y)
        v2 = Vec3(-v.z, 0.0, v.x) / sqrt(v.x^2 + v.z^2)
    else
        v2 = Vec3(0.0, v.z, -v.y) / sqrt(v.y^2 + v.z^2)
    end
    return v, v2, Vec3(cross(v, v2)) # cross product is anti-commutative so need to be v * v2 then cast
end

function face_forward(n, v)::Nml3
    return dot(n, v) < 0.0 ? -n : n
end

function partition!(x::Vector, range::UnitRange, predicate::Function)
    left = range[1]
    for i in range
        if left != i && predicate(x[i])
            x[i], x[left] = x[left], x[i]
            left += 1
        end
    end
    left
end

function same_hemisphere(wo::Vec3, wi::Vec3)::Bool
    return wo.z * wi.z > 0.0
end

function power_heuristic(nf::Float64, fpdf::Float64, ng::Float64, gpdf::Float64)::Float64
    f = nf*fpdf
    g = ng*gpdf
    return (f^2)/(f^2 + g^2)
end

function do_tile(u::Float64, tile::Float64)::Float64
    return (u - trunc((u-eps(Float64))/(1/tile))/tile)*tile
end

function multiplicative_inverse(a::Int64, n::Int64)::Int64
    x = gcd(a,n)
    return mod(x,n)
end

function count_not_undef(iterable::Vector)::Int64
    nope = 0
    for i in 1:length(iterable)
        if isassigned(iterable, i)
            nope += 1
        end
    end
    return nope
end

function round_up_pow2(v::Int64)::Int64
    v -= 1
    v |= v >> 1
    v |= v >> 2
    v |= v >> 4
    v |= v >> 8
    v |= v >> 16
    v |= v >> 32
    return v + 1
end

# https://fgiesen.wordpress.com/2009/12/13/decoding-morton-codes/
# updated to 64 bits.
function left_shift_2(x::UInt64)::UInt64
    x &= 0xffffffff
    x = (x ⊻ (x << 16)) & 0x0000ffff0000ffff
    x = (x ⊻ (x << 8)) & 0x00ff00ff00ff00ff
    x = (x ⊻ (x << 4)) & 0x0f0f0f0f0f0f0f0f
    x = (x ⊻ (x << 2)) & 0x3333333333333333
    x = (x ⊻ (x << 1)) & 0x5555555555555555
    return x
end

function encode_morton_2(x::UInt64, y::UInt64)::UInt64
    # JOHN HACK: using 64 here?
    return (left_shift_2(y) << 1) | left_shift_2(x)
end
          
function gamma(n::Int64)::Float64
    return (n * eps()) / (1.0 - n * eps())
end

function lanczos(x::Float64, tau::Float64)::Float64
    x = abs(x)
    if (x < 1.0e-5) 
        return 1.0
    elseif (x > 1.0)
        return 0.0
    end
    x *= pi
    s = sin(x * tau) / (x * tau)
    l = sin(x) / x
    return s * l
end

function log_2_int(v::UInt32)::Int64
    # JOHN HACK cant I just do floor(log2(v))+1?
    return 31 - leading_zeros(v)
end
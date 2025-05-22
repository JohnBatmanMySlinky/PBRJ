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

function length_squared(v::T)::Float64 where {T <: Union{Vec3, Vec2, Nml3}}
    return sum(v.^2)
end

function length_pbrt(v::Union{Vec3, Vec2})::Float64
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

function safe_acos(f::Float64)::Float64
    return acos(clamp(f, -1.0, 1.0))
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

function lerp(t::Float64, a::T, b::T)::T where {T <: Union{Pnt3, Pnt2, Nml3}}
    return a .+ t .* (b - a)
end

function lerp(t::Pnt3, c::Bounds3)::Pnt3
    return c.pMin .+ t .* (c.pMax - c.pMin)
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

function bound_cubic_bezier(cp::SVector{4, Pnt3}, u_min::Float64, u_max::Float64)::Bounds3
    if (u_min == 0.0) & (u_max == 1.0)
        return bound_cubic_bezier(cp)
    else
        cp_seg = cubic_bezier_control_points(cp, u_min, u_max)
        return bound_cubic_bezier(cp_seg)
    end
end

function bound_cubic_bezier(cp::SVector{4, Pnt3})::Bounds3
    return world_bounds(Bounds3(cp[1], cp[2]), Bounds3(cp[3], cp[4]))
end

function cubic_bezier_control_points(cp::SVector{4, Pnt3}, u_min::Float64, u_max::Float64)::SVector{4, Pnt3}
    return SVector(
        blossom_cubic_bezier(cp, u_min, u_min, u_min),
        blossom_cubic_bezier(cp, u_min, u_min, u_max),
        blossom_cubic_bezier(cp, u_min, u_max, u_max),
        blossom_cubic_bezier(cp, u_max, u_max, u_max)
    )
end

function blossom_cubic_bezier(cp::SVector{4, Pnt3}, u0::Float64, u1::Float64, u2::Float64)::Pnt3
    a = SVector(
        lerp(u0, cp[0+1], cp[1+1]),
        lerp(u0, cp[1+1], cp[2+1]),
        lerp(u0, cp[2+1], cp[3+1])
    )
    b = SVector(
        lerp(u1, a[0+1], a[1+1]),
        lerp(u1, a[1+1], a[2+1]),
    )
    return lerp(u2, b[0+1], b[1+1])
end


function subdivide_cubic_bezier(cp::SVector{4, Pnt3})::SVector{7, Pnt3}
    return SVector(
        cp[0+1],
        (cp[0+1] + cp[1+1]) / 2,
        (cp[0+1] + 2 * cp[1+1] + cp[2+1]) / 4,
        (cp[0+1] + 3 * cp[1+1] + 3 * cp[2+1] + cp[3+1]) / 8,
        (cp[1+1] + 2 * cp[2+1] + cp[3+1]) / 4,
        (cp[2+1] + cp[3+1]) / 2,
        cp[3+1]
    )
end

function evaluate_cubic_bezier(cp::SVector{3, Pnt3}, u::Float64)::Pnt3
    return blossom_cubic_bezier(cp, u, u, u)
end

function evaluate_cubic_bezier_deriv(cp::SVector{4, Pnt3}, u::Float64)::Tuple{Pnt3, Vec3}
    cp1 = SVector(
        lerp(u, cp[0+1], cp[1+1]), 
        lerp(u, cp[1+1], cp[2+1]),
        lerp(u, cp[2+1], cp[3+1])
    )
    cp2 = SVector(
        lerp(u, cp1[0+1], cp1[1+1]), 
        lerp(u, cp1[1+1], cp1[2+1])
    )
    if length_squared(Vec3(cp2[1+1] - cp2[0+1])) > 0
        deriv = 3.0 * (cp2[1+1] - cp2[0+1])
    else
        deriv = cp[3+1] - cp[0+1]
    end
    return lerp(u, cp2[0+1], cp2[1+1]), Vec3(deriv)
end

# 25% faster than exp() so that's nice?
# Shout out Claude for translating this over
# see FastExp_testing.ipynb for benchmarks
function fastexp(x::Float64)
    xp = x * 1.4426950408889634
    fxp = floor(xp)
    f = xp - fxp
    i = Int(fxp)
    
    two_to_f = 1.0 + f * (0.6931471805599453 + f * (0.2402265069591007 + f * 0.0855989669963166))
    
    bits = reinterpret(UInt64, two_to_f)
    exponent = Int((bits >> 52) & 0x7FF) - 1023 + i
    
    if exponent < -1022
        return 0.0
    elseif exponent > 1023
        return Inf
    end
    
    bits = (bits & 0x800FFFFFFFFFFFFF) | (UInt64(exponent + 1023) << 52)
    return reinterpret(Float64, bits)
end

function equal_area_square_to_sphere(p::Pnt2)::Vec3
    @assert (p.x >= 0) && (p.x <= 1) && (p.y >= 0) && (p.y <= 1)
    # Transform _p_ to [-1,1]^2 and compute absolute values
    u = 2.0 * p.x - 1.0
    v = 2.0 * p.y - 1.0
    up = abs(u) 
    vp = abs(v)

    # Compute radius _r_ as signed distance from diagonal
    signedDistance = 1.0 - (up + vp)
    d = abs(signedDistance)
    r = 1.0 - d

    # Compute angle phi for square to sphere mapping
    phi = (r == 0 ? 1.0 : (vp - up) / r + 1.0) * pi / 4.0

    # Find z coordinate for spherical direction
    z = copysign(1 - r^2, signedDistance)

    # Compute cosphi and sinphi for original quadrant and return vector
    cosPhi = copysign(cos(phi), u)
    sinPhi = copysign(sin(phi), v)
    return Vec3(
        cosPhi * r * safe_sqrt(2 - r^2), 
        sinPhi * r * safe_sqrt(2 - r^2),
        z
    )
end

function evaluate_polynomial(x::Float64, coeffs::Float64...)::Float64
    result = coeffs[end]
    for i in length(coeffs)-1:-1:1
        result = result * x + coeffs[i]
    end
    return result
end

function equal_area_sphere_to_square(d::Vec3)::Pnt2
    @assert (length_squared(d) > .99) && (length_squared(d) < 1.001)
    x = abs(d.x)
    y = abs(d.y)
    z = abs(d.z)

    # Compute the radius r
    r = safe_sqrt(1.0 - z)  # r = sqrt(1-|z|)

    # Compute the argument to atan (detect a=0 to avoid div-by-zero)
    a = max(x, y)
    b = min(x, y)
    b = a == 0.0 ? 0.0 : b / a

    # Polynomial approximation of atan(x)*2/pi, x=b
    # Coefficients for 6th degree minimax approximation of atan(x)*2/pi,
    # x=[0,1].
    t1 = 0.406758566246788489601959989e-5
    t2 = 0.636226545274016134946890922156
    t3 = 0.61572017898280213493197203466e-2
    t4 = -0.247333733281268944196501420480
    t5 = 0.881770664775316294736387951347e-1
    t6 = 0.419038818029165735901852432784e-1
    t7 = -0.251390972343483509333252996350e-1
    phi = evaluate_polynomial(b, t1, t2, t3, t4, t5, t6, t7)

    # Extend phi if the input is in the range 45-90 degrees (u<v)
    if (x < y)
        phi = 1.0 - phi
    end

    # Find (u,v) based on (r,phi)
    v = phi * r
    u = r - v

    if (d.z < 0)
        # southern hemisphere -> mirror u,v
        u, v = v, u
        u = 1.0 - u
        v = 1.0 - v
    end

    # Move (u,v) to the correct quadrant based on the signs of (x,y)
    u = copysign(u, d.x)
    v = copysign(v, d.y)

    # Transform (u,v) from [-1,1] to [0,1]
    return Pnt2(0.5 * (u + 1), 0.5 * (v + 1))
end

# Point2f WrapEqualAreaSquare(Point2f uv) {
#     if (uv[0] < 0) {
#         uv[0] = -uv[0]     // mirror across u = 0
#         uv[1] = 1 - uv[1]  // mirror across v = 0.5
#     } else if (uv[0] > 1) {
#         uv[0] = 2 - uv[0]  // mirror across u = 1
#         uv[1] = 1 - uv[1]  // mirror across v = 0.5
#     }
#     if (uv[1] < 0) {
#         uv[0] = 1 - uv[0]  // mirror across u = 0.5
#         uv[1] = -uv[1]     // mirror across v = 0
#     } else if (uv[1] > 1) {
#         uv[0] = 1 - uv[0]  // mirror across u = 0.5
#         uv[1] = 2 - uv[1]  // mirror across v = 1
#     }
#     return uv
# }


# fuck it we binary search
function find_interval(size::Int64, predicate::Function)::Int64
    first = 0
    len = size
    while len > 0
        half = len >> 1
        middle = first + half
        # Bisect range based on value of _pred_ at _middle_
        if predicate(middle)
            first = middle + 1
            len -= half + 1
        else
            len = half
        end
    end
    return clamp(first - 1, 0, size - 2)
end

# Fourier Interpolation Definitions
function fourier_interpolation(a::Vector{Float64}, offset::Int64, m::Int64, cosPhi::Float64)::Float64
    value = 0.0
    # Initialize cosine iterates
    cosKMinusOnePhi = cosPhi
    cosKPhi = 1
    for k in 0:(m-1)
        # Add the current summand and update the cosine iterates
        value += a[offset + k + 1] * cosKPhi
        cosKPlusOnePhi = 2 * cosPhi * cosKPhi - cosKMinusOnePhi
        cosKMinusOnePhi = cosKPhi
        cosKPhi = cosKPlusOnePhi
    end
    return value
end   

function sample_fourier(ak::Vector{Float64}, recip::Vector{Float64}, m::Int64, u::Float64)::Tuple{Float64, Float64, Float64}
    # Pick a side and declare bisection variables
    flip = u >= 0.5
    if flip
        u = 1.0 - 2.0 * (u - 0.5)
    else
        u *= 2
    end
    a = 0.0
    b = pi
    phi = 0.5 * pi
    f_val = 0.0
    F_val = 0.0
    ITER = 0
    MAX_ITER = 1_000
    while true
        ITER += 1
        (ITER > MAX_ITER) && break
        # Evaluate  F( phi) and its derivative  f( phi)

        # Initialize sine and cosine iterates
        cosPhi = cos(phi)
        sinPhi = sqrt(max(0.0, 1 - cosPhi * cosPhi))
        cosPhiPrev = cosPhi
        cosPhiCur = 1.0
        sinPhiPrev = -sinPhi
        sinPhiCur = 0

        # Initialize _F_ and _f_ with the first series term
        F_val = ak[0 + 1] * phi
        f_val = ak[0 + 1]
        for k in 1:(m - 1)
            # Compute next sine and cosine iterates
            sinPhiNext = 2.0 * cosPhi * sinPhiCur - sinPhiPrev
            cosPhiNext = 2.0 * cosPhi * cosPhiCur - cosPhiPrev
            sinPhiPrev = sinPhiCur
            sinPhiCur = sinPhiNext
            cosPhiPrev = cosPhiCur
            cosPhiCur = cosPhiNext

            # Add the next series term to _F_ and _f_
            F_val += ak[k + 1] * recip[k + 1] * sinPhiNext
            f_val += ak[k + 1] * cosPhiNext
        end
        F_val -= u * ak[0 + 1] * pi

        # Update bisection bounds using updated phi
        if F_val > 0
            b = phi
        else
            a = phi
        end

        # Stop the Fourier bisection iteration if converged
        if (abs(F_val) < 1e-6) || (b - a < 1e-6)
            break
        end

        # Perform a Newton step given  f( phi) and  F( phi)
        phi -= F_val / f_val

        # Fall back to a bisection step when  phi is out of bounds
        if (!(phi > a && phi < b)) 
            phi = 0.5 * (a + b)
        end
    end
    # Potentially flip  phi and return the result
    if flip
        phi = 2 * pi - phi
    end
    return f_val, f_val / (ak[0 + 1] * 2 * pi), phi
end

# Spline Interpolation Definitions
function sample_catmull_rom_2D(
    size1::Int64, size2::Int64,
    nodes1::Vector{Float64}, nodes2::Vector{Float64}, 
    values::Vector{Float64}, cdf::Vector{Float64},
    alpha::Float64, u::Float64,
)::Tuple{Float64, Float64, Float64}
    @info "FourierBSDF::SampleCatmullRom2D"
    # Determine offset and coefficients for the _alpha_ parameter
    check, offset, weights = catmull_rom_weights(size1, nodes1, alpha)
    if !check
        return 0.0, 0.0, 0.0
    end
    @info "FourierBSDF::SampleCatmullRom2D: offset = $offset"
    @info "FourierBSDF::SampleCatmullRom2D: weights = $weights"

    # Define a lambda function to interpolate table entries
    function interpolate(array::Vector{Float64}, idx::Int64)::Float64
        value = 0.0
        for i in 0:3
            if weights[i + 1] != 0.0
                value += array[(offset + i) * size2 + idx + 1] * weights[i + 1]
            end
        end
        return value
    end

    # Map _u_ to a spline interval by inverting the interpolated _cdf_
    max_val = interpolate(cdf, size2 - 1)
    @info "FourierBSDF::SampleCatmullRom2D: max_val = $max_val"
    u_scaled = u * max_val
    @info "FourierBSDF::SampleCatmullRom2D: u = $u"
    @info "FourierBSDF::SampleCatmullRom2D: u_scaled = $u_scaled"
    idx = find_interval(size2, z -> interpolate(cdf, z) <= u_scaled)
    @info "FourierBSDF::SampleCatmullRom2D: idx = $idx"

    # Look up node positions and interpolated function values
    f0 = interpolate(values, idx)
    f1 = interpolate(values, idx + 1)
    x0 = nodes2[idx + 1]
    x1 = nodes2[idx + 1 + 1]
    width = x1 - x0

    # Re-scale _u_ using the interpolated _cdf_
    u_scaled = (u_scaled - interpolate(cdf, idx)) / width

    # Approximate derivatives using finite differences of the interpolant
    if (idx > 0)
        d0 = width * (f1 - interpolate(values, idx - 1)) / (x1 - nodes2[idx - 1 + 1])
    else
        d0 = f1 - f0
    end
    if (idx + 2 < size2)
        d1 = width * (interpolate(values, idx + 2) - f0) / (nodes2[idx + 2 + 1] - x0)
    else
        d1 = f1 - f0
    end

    # Invert definite integral over spline segment and return solution

    # Set initial guess for  t by importance sampling a linear interpolant
    if (f0 != f1)
        t = (f0 - sqrt(max(0.0, f0 * f0 + 2.0 * u_scaled * (f1 - f0)))) / (f0 - f1)
    else
        t = u_scaled / f0
    end
    a = 0.0
    b = 1.0
    Fhat = 0.0
    fhat = 0.0
    ITER = 0
    MAX_ITER = 1_000
    while true
        ITER += 1
        (ITER > MAX_ITER) && break
        # Fall back to a bisection step when _t_ is out of bounds
        if (!(t >= a && t <= b)) 
            t = 0.5 * (a + b)
        end

        # Evaluate target function and its derivative in Horner form
        Fhat = t * (f0 +
                    t * (0.5 * d0 +
                         t * ((1.0 / 3.0) * (-2.0 * d0 - d1) + f1 - f0 +
                              t * (0.25 * (d0 + d1) + 0.5 * (f0 - f1)))))
        fhat = f0 +
               t * (d0 +
                    t * (-2.0 * d0 - d1 + 3.0 * (f1 - f0) +
                         t * (d0 + d1 + 2.0 * (f0 - f1))))

        # Stop the iteration if converged
        if ((abs(Fhat - u) < 1e-6) || (b - a < 1e-6)) 
            break
        end

        # Update bisection bounds using updated _t_
        if (Fhat - u_scaled < 0.0)
            a = t
        else
            b = t
        end

        # Perform a Newton step
        t -= (Fhat - u_scaled) / fhat
    end

    # Return the sample position and function value
    return (x0 + width * t, fhat, fhat / max_val)
end

function catmull_rom_weights(size::Int64, nodes::Vector{Float64}, x::Float64)::Tuple{Bool, Int64, Vector{Float64}}
    weights = zeros(Float64, 4)
    # Return _false_ if _x_ is out of bounds
    @info "FourierBSDF::CatmullRomWeights"
    if !((x >= nodes[0+1]) && (x <= nodes[size - 1 + 1]))
        return (false, 0, 0.0)
    end

    # Search for the interval _idx_ containing _x_
    idx = find_interval(size, v -> nodes[v] <= x) - 1
    @info "FourierBSDF::CatmullRomWeights size $size"
    @info "FourierBSDF::CatmullRomWeights x $x"
    @info "FourierBSDF::CatmullRomWeights idx $idx"

    offset = idx - 1
    x0 = nodes[idx + 1]
    x1 = nodes[idx + 1 + 1]
    @info "FourierBSDF::CatmullRomWeights x0 $x0"
    @info "FourierBSDF::CatmullRomWeights x1 $x1"

    # Compute the  t parameter and powers
    t = (x - x0) / (x1 - x0)
    t2 = t * t
    t3 = t2 * t
    @info "FourierBSDF::CatmullRomWeights t $t"
    @info "FourierBSDF::CatmullRomWeights t2 $t2"
    @info "FourierBSDF::CatmullRomWeights t3 $t3"

    # Compute initial node weights  w_1 and  w_2
    weights[1 + 1] = 2 * t3 - 3 * t2 + 1
    weights[2 + 1] = -2 * t3 + 3 * t2
    @info "FourierBSDF::CatmullRomWeights weights $weights"

    # Compute first node weight  w_0
    if (idx > 0)
        w0 = (t3 - 2 * t2 + t) * (x1 - x0) / (x1 - nodes[idx - 1 + 1])
        weights[0 + 1] = -w0
        weights[2 + 1] += w0
    else
        w0 = t3 - 2 * t2 + t
        weights[0 + 1] = 0.0
        weights[1 + 1] -= w0
        weights[2 + 1] += w0
    end
    @info "FourierBSDF::CatmullRomWeights weights $weights"

    # Compute last node weight  w_3
    if (idx + 2 < size)
        w3 = (t3 - t2) * (x1 - x0) / (nodes[idx + 2 + 1] - x0)
        weights[1 + 1] -= w3
        weights[3 + 1] = w3
    else
        w3 = t3 - t2
        weights[1 + 1] -= w3
        weights[2 + 1] += w3
        weights[3 + 1] = 0.0
    end
    @info "FourierBSDF::CatmullRomWeights weights $weights"
    return (true, offset, weights)
end

"""
Float CatmullRom(int size, const Float *nodes, const Float *values, Float x) {
    if (!(x >= nodes[0] && x <= nodes[size - 1])) return 0;
    int idx = FindInterval(size, [&](int i) { return nodes[i] <= x; });
    Float x0 = nodes[idx], x1 = nodes[idx + 1];
    Float f0 = values[idx], f1 = values[idx + 1];
    Float width = x1 - x0;
    Float d0, d1;
    if (idx > 0)
        d0 = width * (f1 - values[idx - 1]) / (x1 - nodes[idx - 1]);
    else
        d0 = f1 - f0;

    if (idx + 2 < size)
        d1 = width * (values[idx + 2] - f0) / (nodes[idx + 2] - x0);
    else
        d1 = f1 - f0;

    Float t = (x - x0) / (x1 - x0), t2 = t * t, t3 = t2 * t;
    return (2 * t3 - 3 * t2 + 1) * f0 + (-2 * t3 + 3 * t2) * f1 +
           (t3 - 2 * t2 + t) * d0 + (t3 - t2) * d1;
}

Float SampleCatmullRom(int n, const Float *x, const Float *f, const Float *F,
                       Float u, Float *fval, Float *pdf) {
    // Map _u_ to a spline interval by inverting _F_
    u *= F[n - 1];
    int i = FindInterval(n, [&](int i) { return F[i] <= u; });

    // Look up  x_i and function values of spline segment _i_
    Float x0 = x[i], x1 = x[i + 1];
    Float f0 = f[i], f1 = f[i + 1];
    Float width = x1 - x0;

    // Approximate derivatives using finite differences
    Float d0, d1;
    if (i > 0)
        d0 = width * (f1 - f[i - 1]) / (x1 - x[i - 1]);
    else
        d0 = f1 - f0;
    if (i + 2 < n)
        d1 = width * (f[i + 2] - f0) / (x[i + 2] - x0);
    else
        d1 = f1 - f0;

    // Re-scale _u_ for continous spline sampling step
    u = (u - F[i]) / width;

    // Invert definite integral over spline segment and return solution

    // Set initial guess for  t by importance sampling a linear interpolant
    Float t;
    if (f0 != f1)
        t = (f0 - std::sqrt(std::max((Float)0, f0 * f0 + 2 * u * (f1 - f0)))) /
            (f0 - f1);
    else
        t = u / f0;
    Float a = 0, b = 1, Fhat, fhat;
    while (true) {
        // Fall back to a bisection step when _t_ is out of bounds
        if (!(t > a && t < b)) t = 0.5f * (a + b);

        // Evaluate target function and its derivative in Horner form
        Fhat = t * (f0 +
                    t * (.5f * d0 +
                         t * ((1.f / 3.f) * (-2 * d0 - d1) + f1 - f0 +
                              t * (.25f * (d0 + d1) + .5f * (f0 - f1)))));
        fhat = f0 +
               t * (d0 +
                    t * (-2 * d0 - d1 + 3 * (f1 - f0) +
                         t * (d0 + d1 + 2 * (f0 - f1))));

        // Stop the iteration if converged
        if (std::abs(Fhat - u) < 1e-6f || b - a < 1e-6f) break;

        // Update bisection bounds using updated _t_
        if (Fhat - u < 0)
            a = t;
        else
            b = t;

        // Perform a Newton step
        t -= (Fhat - u) / fhat;
    }

    // Return the sample position and function value
    if (fval) *fval = fhat;
    if (pdf) *pdf = fhat / F[n - 1];
    return x0 + width * t;
}

Float IntegrateCatmullRom(int n, const Float *x, const Float *values,
                          Float *cdf) {
    Float sum = 0;
    cdf[0] = 0;
    for (int i = 0; i < n - 1; ++i) {
        // Look up  x_i and function values of spline segment _i_
        Float x0 = x[i], x1 = x[i + 1];
        Float f0 = values[i], f1 = values[i + 1];
        Float width = x1 - x0;

        // Approximate derivatives using finite differences
        Float d0, d1;
        if (i > 0)
            d0 = width * (f1 - values[i - 1]) / (x1 - x[i - 1]);
        else
            d0 = f1 - f0;
        if (i + 2 < n)
            d1 = width * (values[i + 2] - f0) / (x[i + 2] - x0);
        else
            d1 = f1 - f0;

        // Keep a running sum and build a cumulative distribution function
        sum += ((d0 - d1) * (1.f / 12.f) + (f0 + f1) * .5f) * width;
        cdf[i + 1] = sum;
    }
    return sum;
}

Float InvertCatmullRom(int n, const Float *x, const Float *values, Float u) {
    // Stop when _u_ is out of bounds
    if (!(u > values[0]))
        return x[0];
    else if (!(u < values[n - 1]))
        return x[n - 1];

    // Map _u_ to a spline interval by inverting _values_
    int i = FindInterval(n, [&](int i) { return values[i] <= u; });

    // Look up  x_i and function values of spline segment _i_
    Float x0 = x[i], x1 = x[i + 1];
    Float f0 = values[i], f1 = values[i + 1];
    Float width = x1 - x0;

    // Approximate derivatives using finite differences
    Float d0, d1;
    if (i > 0)
        d0 = width * (f1 - values[i - 1]) / (x1 - x[i - 1]);
    else
        d0 = f1 - f0;
    if (i + 2 < n)
        d1 = width * (values[i + 2] - f0) / (x[i + 2] - x0);
    else
        d1 = f1 - f0;

    // Invert the spline interpolant using Newton-Bisection
    Float a = 0, b = 1, t = .5f;
    Float Fhat, fhat;
    while (true) {
        // Fall back to a bisection step when _t_ is out of bounds
        if (!(t > a && t < b)) t = 0.5f * (a + b);

        // Compute powers of _t_
        Float t2 = t * t, t3 = t2 * t;

        // Set _Fhat_ using Equation (8.27)
        Fhat = (2 * t3 - 3 * t2 + 1) * f0 + (-2 * t3 + 3 * t2) * f1 +
               (t3 - 2 * t2 + t) * d0 + (t3 - t2) * d1;

        // Set _fhat_ using Equation (not present)
        fhat = (6 * t2 - 6 * t) * f0 + (-6 * t2 + 6 * t) * f1 +
               (3 * t2 - 4 * t + 1) * d0 + (3 * t2 - 2 * t) * d1;

        // Stop the iteration if converged
        if (std::abs(Fhat - u) < 1e-6f || b - a < 1e-6f) break;

        // Update bisection bounds using updated _t_
        if (Fhat - u < 0)
            a = t;
        else
            b = t;

        // Perform a Newton step
        t -= (Fhat - u) / fhat;
    }
    return x0 + t * width;
}

// Fourier Interpolation Definitions
"""
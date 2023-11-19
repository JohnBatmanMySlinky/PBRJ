function random_in_concentric_disk(u::Pnt2)::Pnt2
    offset::Pnt2 = 2.0 .* u - Pnt2(1.0, 1.0)

    if all(offset .== 0.0)
        return Pnt2(0.0, 0.0)
    end

    r::Float64 = 0.0
    theta::Float64 = 0.0
    if abs(offset.x) > abs(offset.y)
        r = offset.x
        theta = (offset.y / offset.x) * pi / 4.0
    else
        r = offset.y
        theta = pi / 2.0 - (offset.x / offset.y) * pi / 4.0
    end
    return Pnt2(cos(theta), sin(theta)) .* r
end

function random_in_cosine_hemisphere(u::Pnt2)::Pnt3
    d = random_in_concentric_disk(u)
    z = sqrt(max(0.0, 1-d.y^2 - d.y^2))
    return Pnt3(d.x, d.y, z)
end

function random_on_sphere(u::Pnt2)::Pnt3
    z = 1.0 - 2.0 * u.x
    r = sqrt(max(0, 1-z^2))
    phi = 2 * pi * u.y
    return Vec3(r *cos(phi), r*sin(phi), z)
end

function cosine_sample_hemisphere(u::Pnt2)::Vec3
    d = random_in_concentric_disk(u)
    z = sqrt(max(0.0 ,1-d.x^2-d.y^2))
    return Vec3(d.x, d.y, z)
end

function uniform_sample_cone(u1::Pnt2, cos_theta_max::Float64)::Vec3
    cos_theta = 1.0 - u1.x + u1.x * cos_theta_max
    sin_theta = sqrt(1.0-cos_theta^2)
    phi = u1.y * 2.0 * pi
    return Vec3(cos(phi)*sin_theta, sin(phi)*sin_theta, cos_theta)
end

function cosine_hemisphere_pdf(cos_theta::Float64)::Float64
    return cos_theta / pi
end

function uniform_cone_pdf(cos_theta_max::Float64)::Float64
    return 1.0 / (2.0 * pi * (1-cos_theta_max))
end

function sample_linear(u::Float64, a::Float64, b::Float64)::Float64
    if (u == 0.0) && (a == 0.0)
        return 0.0
    end

    x = u * (a + b) / (a + sqrt(lerp(u, a^2, b^2)))
    return min(x, 1.0-eps())
end

function sample_bilinear(u::Pnt2, w::Vec4)::Pnt2
    # sample $y$ for bilinear marginal distribution
    uno = sample_linear(u.y, w.x + w.y, w.z + w.a)

    # sample $x$ for the bilinear marginal distribution
    dos = sample_linear(
        u.x,
        lerp(uno, w.x, w.z),
        lerp(uno, w.y, w.a)
    )
    return Pnt2(uno, dos)
end

function bilinear_pdf(p::Pnt2, w::Vec4)::Float64
    if (p.x < 0.0) || (p.x > 1.0) || (p.y < 0.0) || (p.y > 1.0)
        return 0.0
    elseif w.x + w.y + w.z + w.a == 0.0
        return 1.0
    else
        return 4.0 * ((1 - p.x) * (1 - p.y) * w.x + p.x * (1 - p.y) * w.y + (1 - p.x) * p.y * w.z + p.x * p.y * w.a) / (w.x + w.y + w.z + w.a)
    end
end

function sample_spherical_triangle(v1::Pnt3, v2::Pnt3, v3::Pnt3, p::Pnt3, u::Pnt2)::Tuple{Pnt3, Float64}
    # compute vectors _a_, _b_, and _c_ to spherical triangle vertices
    a = Vec3(v1 - p)
    b = Vec3(v2 - p)
    c = Vec3(v3 - p)
    @assert length_squared(a) > 0.0
    @assert length_squared(b) > 0.0
    @assert length_squared(c) > 0.0
    a = normalize(a)
    b = normalize(b)
    c = normalize(c)

    # compute the normalized cross produts of all direction pairs
    n_ab = cross(a,b)
    n_bc = cross(b,c)
    n_ca = cross(c,a)

    if (length_squared(n_ab) == 0.0) || (length_squared(n_bc) == 0.0) || (length_squared(n_ca) == 0.0)
        return Pnt3(0.0, 0.0, 0.0), 0.0
    end

    n_ab = normalize(n_ab)
    n_bc = normalize(n_bc)
    n_ca = normalize(n_ca)

    # find angles $alpha#, $beta$ and $gamma$ at speherical triangle vertices
    alpha = angle_between(n_ab, -n_ca)
    beta = angle_between(n_bc, -n_ab)
    gamma = angle_between(n_ca, -n_bc)

    # uniformly sample triangle area $A$ to compute $As$
    A_pi = alpha + beta + gamma
    Ap_pi = lerp(u.x, Float64(pi), A_pi)
    A = A_pi - pi
    pdf_val = (A <= 0.0) ? 0.0 : 1.0 / A

    # find $cos(beta)'s$ for point along _b_ for sampled area
    cos_alpha = cos(alpha)
    sin_alpha = sin(alpha)
    sin_phi = sin(Ap_pi) * cos_alpha - cos(Ap_pi) * sin_alpha
    cos_phi = cos(Ap_pi) * cos_alpha + sin(Ap_pi) * sin_alpha

    k1 = cos_phi + cos_alpha
    k2 = sin_phi - sin_alpha * dot(a,b) 
    cos_bp = (k2 + difference_of_products(k2, cos_phi, k1, sin_phi) * cos_alpha) / (sum_of_products(k2, sin_phi, k1, cos_phi) * sin_alpha)

    # happens if the triangle basically covers the entire hemisphere.
    # we currently depend on calling code to deteect this case, which is sort of ugly / unfortunate
    # JOHN HACK skipping is nan
    cos_bp = clamp(cos_bp, -1.0, 1.0)

    # sample $c'$ along the arc between $b'$ and $a$
    sin_bp = safe_sqrt(1.0 - cos_bp^2)
    cp = cos_bp * a + sin_bp * normalize(gram_schmidt(c,a))

    # compute sampled spherical triangle direction and return barycentrics
    cos_theta = 1.0 - u.y - (1.0 - dot(cp, b))
    sin_theta = safe_sqrt(1.0 - cos_theta^2)
    w = cos_theta * b + sin_theta * normalize(gram_schmidt(cp, b))
    # find barycentric coordinates for sampled direction _w_
    e1 = v2 - v1
    e2 = v3 - v1
    s1 = cross(w, e2)
    divisor = dot(s1, e1)
    if divisor == 0.0
        # this happens with triangles that cover nearly the whole hemisphere
        return Pnt3(1.0 / 3.0, 1.0 / 3.0, 1.0 / 3.0), pdf_val
    end

    inv_divisor = 1.0 / divisor
    s = p - v1
    b1 = dot(s, s1) * inv_divisor
    b2 = dot(w, cross(s, e1)) * inv_divisor

    # return clamped barycentrics for sampled direction
    b1 = clamp(b1, 0.0, 1.0)
    b2 = clamp(b2, 0.0, 1.0)
    if b1 + b2 > 1.0
        b1 /= (b1 + b2)
        b2 /= (b1 + b2)
    end
    return Pnt3(1.0 - b1 - b2, b1, b2), pdf_val
end
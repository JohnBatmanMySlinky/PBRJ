const Option{T} = Union{Missing, T}
const Vec3 = SVector{3, Float64}

function unit_vector(v::Vec3)::Vec3
    return v ./ norm(v)
end

function random_in_unit_sphere()::Vec3
    p = Vec3(1.0, 1.0, 1.0)
    while norm(p) >= 1.0
        p = 2.0 .* Vec3(rand(3)...) - Vec3(1.0, 1.0, 1.0)
    end
    return p
end

function random_unit_vector()::Vec3
    return unit_vector(random_in_unit_sphere())
end

function random_in_hemisphere(normal::Vec3)::Vec3
    in_unit_sphere = random_in_unit_sphere()
    if dot(in_unit_sphere, normal) > 0
        return in_unit_sphere 
    else
        return -in_unit_sphere
    end
end

function near_zero(v::Vec3)::Bool
    eps = 1e-8
    return (v[1] < eps) && (v[2] < eps) && (v[3] < eps)
end

function random_in_unit_disk()::Vec3
    p = Vec3(1.0, 1.0, 0)
    while norm(p) >= 1.0
        p = 2.0 .* Vec3(rand(), rand(), 0) - Vec3(1.0, 1.0, 0)
    end
    return p
end

function rand_between(a::Union{Float64,Int64},b::Union{Float64,Int64})::Float64
    if a == b
        return a
    else
        return rand(Uniform(a,b))
    end
end

function random_cosine_direction()::Vec3
    r1 = rand()
    r2 = rand()
    z = sqrt(1-r2)

    phi = 2*pi*r1
    x = cos(phi)*sqrt(r2)
    y = sin(phi)*sqrt(r2)

    return Vec3(x,y,z)
end

function random_cosine_direction(r1::Float64, r2::Float64)::Vec3
    z = sqrt(1-r2)

    phi = 2*pi*r1
    x = cos(phi)*sqrt(r2)
    y = sin(phi)*sqrt(r2)

    return Vec3(x,y,z)
end

function random_to_sphere(r::Float64, distance_squared::Float64)::Vec3
    r1 = rand()
    r2 = rand()
    z = 1 + r2*(sqrt(max(0,1-r*r/distance_squared))-1)

    phi = 2*pi*r1
    x = cos(phi)*sqrt(1-z^2)
    y = sin(phi)*sqrt(1-z^2)

    return Vec3(x,y,z)
end

function random_to_sphere(r::Float64, u::Float64, v::Float64)::Vec3
    theta = pi * u
    phi = 2 * pi * v
    x = r * sin(theta) * cos(phi)
    y = r * sin(theta) * sin(phi)
    z = r * cos(theta)
    return Vec3(x,y,z)
end

function get_sphere_uv(p::Vec3)::Vec3
    theta = acos(-p[2])
    phi = atan(-p[3], p[1]) + pi

    u = phi / (2pi)
    v = theta / pi
    return Vec3(u, v, 0)
end
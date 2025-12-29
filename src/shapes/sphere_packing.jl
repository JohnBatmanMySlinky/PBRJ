# Taken from: https://github.com/Libbum/spherical-cow/tree/master

# extend SimpleSphere
function volume(s::SimpleSphere)::Float64
    return (4.0 / 3.0) * pi * s.r^3
end

function overlaps(s1::SimpleSphere, s2::SimpleSphere)::Bool
    dist = norm(s1.p - s2.p)
    return dist < (s1.r + s2.r)
end

function contains(container::SimpleSphere, sphere::SimpleSphere)::Bool
    dist = norm(sphere.p - container.p)
    return dist + sphere.r <= container.r
end

# extend Bounds3
function contains(container::Bounds3, sphere::SimpleSphere)::Bool
    c = sphere.p
    r = sphere.r
    return all(container.min_point .+ r .<= c .<= container.max_point .- r)
end

function volume(c::Bounds3)::Float64
    return prod(c.max_point - c.min_point)
end

# Triangle Mesh

struct SimpleTriangle
    p1::Pnt3
    p2::Pnt3
    p3::Pnt3
end
struct TriangleMesh
    triangles::Vector{SimpleTriangle}
    volume_val::Float64
    
    function TriangleMesh(triangles::Vector{Triangle})
        simple_tris = [SimpleTriangle(triangle.vertices[1], triangle.vertices[2], triangle.vertices[3]) for triangle in triangles]
        vol = trimesh_volume(simple_tris)
        new(simple_tris, vol)
    end
end

function contains(mesh::TriangleMesh, sphere::SimpleSphere)::Bool
    # Ray casting: shoot a ray from the origin through the sphere center
    # Count intersections. Even = outside, Odd = inside
    
    # Distance from origin to sphere center plus radius
    o_dist = norm(sphere.p) + sphere.r
    
    # Unit vector from origin pointing toward sphere center
    norm_dir = normalize(sphere.p)
    
    # Count ray intersections from origin through the sphere
    count = ray_intersection_count(mesh.triangles, norm_dir, o_dist)
    
    # In Rust: is_odd checks if count is odd
    # If odd, sphere is OUTSIDE (return false)
    # If even, sphere is INSIDE (return true)
    is_odd = count % 2 == 1
    
    if is_odd
        return false  # Sphere is outside
    else
        return true   # Sphere is inside
    end
end

function volume(m::TriangleMesh)::Float64
    return m.volume_val
end

Container = Union{SimpleSphere, Bounds3, TriangleMesh}

# Utility functions for triangle mesh
function ray_intersection_count(triangles::Vector{SimpleTriangle}, dir::Pnt3, o_dist::Float64)::Int64
    count = 0
    for triangle in triangles
        vert0 = triangle.p1
        vert1 = triangle.p2
        vert2 = triangle.p3

        edge1 = vert1 - vert0
        edge2 = vert2 - vert0
        pvec = cross(dir, edge2)
        det = dot(edge1, pvec)
        
        if abs(det) < 1e-6
            continue
        end
        
        inv_det = 1.0 / det
        tvec = -vert0  # Origin (0,0,0) - vert0
        u = dot(tvec, pvec) * inv_det
        
        if !(0.0 <= u <= 1.0)
            continue
        end
        
        qvec = cross(tvec, edge1)
        v = dot(dir, qvec) * inv_det
        
        if v < 0.0 || u + v > 1.0
            continue
        end
        
        t = dot(edge2, qvec) * inv_det
        if t > 0.0 && t < o_dist  # Only count if intersection is between origin and sphere edge
            count += 1
        end
    end
    return count
end

function trimesh_volume(triangles::Vector{SimpleTriangle})::Float64
    vol = 0.0
    for triangle in triangles
        a = triangle.p1
        b = triangle.p2
        c = triangle.p3
        # Tetrahedron volume with origin as fourth vertex
        vol += (1.0 / 6.0) * (
            -c[1] * b[2] * a[3] + b[1] * c[2] * a[3] + 
            c[1] * a[2] * b[3] - a[1] * c[2] * b[3] - 
            b[1] * a[2] * c[3] + a[1] * b[2] * c[3]
        )
    end
    return abs(vol)
end

function distance_to_triangle(p::Pnt3, v0::Pnt3, 
                            v1::Pnt3, v2::Pnt3)
    # Simple approximation - distance to plane of triangle
    n = normalize(cross(v1 - v0, v2 - v0))
    return abs(dot(p - v0, n))
end

# PackedVolume structure
struct PackedVolume{C <: Container}
    spheres::Vector{SimpleSphere}
    container::C
end

function PackedVolume(container::C, size_dist::D) where {C <: Container, D <: Distribution}
    spheres = pack_spheres(container, size_dist)
    return PackedVolume(spheres, container)
end

function volume_fraction(pv::PackedVolume)
    vol_spheres = sum(volume(s) for s in pv.spheres)
    return vol_spheres / volume(pv.container)
end

function void_ratio(pv::PackedVolume)
    vol_spheres = sum(volume(s) for s in pv.spheres)
    vol_total = volume(pv.container)
    return (vol_total - vol_spheres) / vol_spheres
end

function coordination_number(pv::PackedVolume)
    num_particles = length(pv.spheres)
    coordinations = 0
    for i in 1:num_particles
        coordinations += sphere_contacts_count(pv, i)
    end
    return coordinations / num_particles
end

function sphere_contacts_count(pv::PackedVolume, sphere_idx::Int)
    center = pv.spheres[sphere_idx].p
    radius = pv.spheres[sphere_idx].r
    count = 0
    for (i, sphere) in enumerate(pv.spheres)
        if i == sphere_idx
            continue
        end
        dist = norm(center - sphere.p)
        if isapprox(dist, radius + sphere.r, rtol=0.0001)
            count += 1
        end
    end
    return count
end

function sphere_contacts(pv::PackedVolume, sphere_idx::Int)
    center = pv.spheres[sphere_idx].p
    radius = pv.spheres[sphere_idx].r
    contacts = Sphere[]
    for sphere in pv.spheres
        dist = norm(center - sphere.p)
        if dist > 0 && isapprox(dist, radius + sphere.r, rtol=0.0001)
            push!(contacts, sphere)
        end
    end
    return contacts
end

function fabric_tensor(pv::PackedVolume)
    n = length(pv.spheres)
    F = zeros(Float64, 3, 3)
    
    for idx in 1:n
        center = pv.spheres[idx].p
        p_c = sphere_contacts(pv, idx)
        m_p = length(p_c)
        
        if m_p == 0
            continue
        end
        
        for c in p_c
            vec_n_pc = c.p - center
            n_pc = normalize(vec_n_pc)
            for i in 1:3, j in 1:3
                F[i,j] += n_pc[i] * n_pc[j] / m_p
            end
        end
    end
    
    return F / n
end

# Main packing algorithm
function pack_spheres(container::C, size_dist::D) where {C <: Container, D <: Distribution}
    rng = MersenneTwister()
    
    # Initial three spheres
    init_radii = Float64[rand(rng, size_dist), rand(rng, size_dist), rand(rng, size_dist)]
    spheres = init_spheres(init_radii, container)
    front = copy(spheres)
    
    new_radius = Float64(rand(rng, size_dist))
    
    set_v = SimpleSphere[]
    set_f = SimpleSphere[]
    
    while !isempty(front)
        # Pick random sphere from front
        curr_sphere = front[rand(rng, 1:length(front))]
        
        # Find neighboring spheres
        empty!(set_v)
        for s in spheres
            if s != curr_sphere
                dist = norm(curr_sphere.p - s.p)
                if dist <= curr_sphere.r + s.r + 2 * new_radius
                    push!(set_v, s)
                end
            end
        end
        
        placed = false
        # Try all pairs of neighbors
        for (s_i, s_j) in combinations(set_v, 2)
            empty!(set_f)
            identify_f!(set_f, curr_sphere, s_i, s_j, container, set_v, new_radius)
            
            if !isempty(set_f)
                # Place new sphere
                s_new = set_f[rand(rng, 1:length(set_f))]
                push!(front, s_new)
                push!(spheres, s_new)
                new_radius = Float64(rand(rng, size_dist))
                placed = true
                break
            end
        end
        
        if !placed
            # Remove current sphere from front
            filter!(s -> s != curr_sphere, front)
        end
    end
    
    return spheres
end

function init_spheres(radii::Vector{Float64}, container::C) where C <: Container
    radius_a, radius_b, radius_c = radii
    
    # Triangle side lengths
    distance_c = radius_a + radius_b
    distance_b = radius_a + radius_c  
    distance_a = radius_b + radius_c
    
    # Triangle coordinates
    b_2 = distance_b^2
    x = (b_2 + distance_c^2 - distance_a^2) / (2 * distance_c)
    y = sqrt(b_2 - x^2)
    
    # Incenter
    perimeter = distance_a + distance_b + distance_c
    incenter_x = (distance_b * distance_c + distance_c * x) / perimeter
    incenter_y = (distance_c * y) / perimeter
    
    # Create spheres offset by incenter
    s_1 = SimpleSphere(Pnt3(-incenter_x, -incenter_y, 0.0), radius_a)
    s_2 = SimpleSphere(Pnt3(distance_c - incenter_x, -incenter_y, 0.0), radius_b)
    s_3 = SimpleSphere(Pnt3(x - incenter_x, y - incenter_y, 0.0), radius_c)
    
    # Check containment
    if !contains(container, s_1) || !contains(container, s_2) || !contains(container, s_3)
        println("HUH $s_1, $s_2, $s_3")
        throw("Initial spheres not contained")
    end
    
    return [s_1, s_2, s_3]
end

function identify_f!(set_f::Vector{SimpleSphere}, s_1::SimpleSphere, s_2::SimpleSphere, s_3::SimpleSphere,
                    container::C, set_v::Vector{SimpleSphere}, radius::Float64) where C <: Container
    
    # Distances from new sphere center to existing sphere centers
    distance_14 = s_1.r + radius
    distance_24 = s_2.r + radius
    distance_34 = s_3.r + radius
    
    # Vectors and unit vectors
    vector_u = s_1.p - s_2.p
    unitvector_u = normalize(vector_u)
    vector_v = s_1.p - s_3.p
    unitvector_v = normalize(vector_v)
    unitvector_t = normalize(cross(vector_u, vector_v))
    vector_w = -2.0 * s_1.p
    
    # Calculate distances
    distance_c = distance_14^2 - dot(s_1.p, s_1.p)
    distance_a = (distance_24^2 - distance_c - dot(s_2.p, s_2.p)) / (2 * norm(vector_u))
    distance_b = (distance_34^2 - distance_c - dot(s_3.p, s_3.p)) / (2 * norm(vector_v))
    
    # Dot products
    dot_uv = dot(unitvector_u, unitvector_v)
    dot_wt = dot(vector_w, unitvector_t)
    dot_uw = dot(unitvector_u, vector_w)
    dot_vw = dot(unitvector_v, vector_w)
    
    # Solve for position
    denominator = 1 - dot_uv^2
    alpha = (distance_a - distance_b * dot_uv) / denominator
    beta = (distance_b - distance_a * dot_uv) / denominator
    value_d = alpha^2 + beta^2 + 2 * alpha * beta * dot_uv + 
              alpha * dot_uw + beta * dot_vw - distance_c
    
    # Check for real solutions
    discriminant = dot_wt^2 - 4 * value_d
    if discriminant > 0
        sqrt_disc = sqrt(discriminant)
        gamma_pos = 0.5 * (-dot_wt + sqrt_disc)
        gamma_neg = 0.5 * (-dot_wt - sqrt_disc)
        
        # Two possible positions
        pos_center = alpha * unitvector_u + beta * unitvector_v + gamma_pos * unitvector_t
        neg_center = alpha * unitvector_u + beta * unitvector_v + gamma_neg * unitvector_t
        
        s_4_positive = SimpleSphere(pos_center, radius)
        s_4_negative = SimpleSphere(neg_center, radius)
        
        # Check containment and non-overlap
        if contains(container, s_4_positive) && !any(s -> overlaps(s, s_4_positive), set_v)
            push!(set_f, s_4_positive)
        end
        if contains(container, s_4_negative) && !any(s -> overlaps(s, s_4_negative), set_v)
            push!(set_f, s_4_negative)
        end
    end
end
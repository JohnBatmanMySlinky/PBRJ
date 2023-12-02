struct TriangleMesh
    n_triangles::Int64
    n_vertices::Int64
    vertices::Vector{Pnt3}
    indices::Vector{Int64}
    normals::Vector{Nml3}
    uvs::Vector{Pnt2}
    alpha_mask::Maybe{Texture}
    shading_tangent::Nothing

    function TriangleMesh(
        object_to_world::Transformation, 
        n_triangles::Int64, 
        n_vertices::Int64, 
        vertices::Vector{Pnt3}, 
        indices::Vector{Int64}, 
        normals::Vector{Nml3},
        uvs::Vector{Pnt2},
        alpha_mask::Maybe{Texture},
    )
        vertices = object_to_world.(vertices)
        normals = object_to_world.(normals)
        new(
            n_triangles,
            n_vertices,
            vertices,
            indices,
            normals,
            uvs,
            alpha_mask,
            nothing
        )
    end
end

struct Triangle <: Shape
    core::ShapeCore
    mesh::TriangleMesh
    i::Int64
    
    function Triangle(core::ShapeCore, mesh::TriangleMesh, i::Int64)
        new(core, mesh, i*3+1)
    end
end

###################################################
###### Instantiate a triangle mesh manually #######
###################################################

function construct_triangle_mesh(
    core::ShapeCore, 
    n_triangles::Int64, 
    n_vertices::Int64, 
    vertices::Vector{Pnt3}, 
    indices::Vector{Int64}, 
    normals::Vector{Nml3},
    uvs::Vector{Pnt2},
    alpha_mask::Maybe{Texture},
)
    mesh = TriangleMesh(
        core.object_to_world, 
        n_triangles, 
        n_vertices, 
        vertices, 
        indices, 
        normals, 
        uvs,
        alpha_mask
    )
    return [Triangle(core, mesh, i) for i in 0:n_triangles - 1]
end

###################################################
#### Get Bounds Working ###########################
###################################################

# PBR 3.6.1
# "The Triangle shape is one of the shapes that can compute a better world space bound than can be found by transforming its 
# object space bounding box to world space. Its world space bound can be directly computed from the world space vertices."
function ObjectBounds(tri::Triangle)
    # TODO
    # triangles have their vertices already in world space so go backwards because
    # results of this function are transformed back
    # ugh
    p0, p1, p2 = tri.core.world_to_object.(get_vertices(tri))
    # TODO why must I do this
    buffer = Float64[0, 0, 0]
    for i in 1:3
        if p0[i] == p1[i] == p2[i]
            buffer[i] = .0001
        end
    end
    return world_bounds(world_bounds(Bounds3(p0-buffer, p0+buffer), Bounds3(p1-buffer, p1+buffer)), Bounds3(p2-buffer, p2+buffer))
end

##############################
####### Helper Functions #####
##############################

@inline function get_vertices(t::Triangle)::Tuple{Pnt3, Pnt3, Pnt3}
    return t.mesh.vertices[t.mesh.indices[t.i + 0]], t.mesh.vertices[t.mesh.indices[t.i + 1]], t.mesh.vertices[t.mesh.indices[t.i + 2]]
end

@inline function get_normals(t::Triangle)::Tuple{Nml3, Nml3, Nml3}
    # TODO implement ability to NOT have normals
    return t.mesh.normals[t.mesh.indices[t.i + 0]], t.mesh.normals[t.mesh.indices[t.i + 1]], t.mesh.normals[t.mesh.indices[t.i + 2]]
end

@inline function get_uvs(t::Triangle)::Tuple{Pnt2, Pnt2, Pnt2}
    # TODO implement ability to NOT have UVs
    return t.mesh.uvs[t.mesh.indices[t.i + 0]], t.mesh.uvs[t.mesh.indices[t.i + 1]], t.mesh.uvs[t.mesh.indices[t.i + 2]]
end

##################################################
######### Intersect ##############################
##################################################

# PBR 3.6.2
function intersect(tri::Triangle, ray::AbstractRay, ::Bool=false)::Tuple{Bool, Maybe{Float64}, Maybe{SurfaceInteraction}}
    # get triangle vertices
    p0, p1, p2 = get_vertices(tri)
    
    # perform ray-triangle intersection test
    ## transform vertices to ray coord space
    p0t = Pnt3(p0 - Vec3(ray.origin))
    p1t = Pnt3(p1 - Vec3(ray.origin))
    p2t = Pnt3(p2 - Vec3(ray.origin))
    kz = argmax(abs.(ray.direction))
    kx = kz + 1
    if kx == 4
        kx = 1
    end
    ky = kx + 1
    if ky == 4
        ky = 1
    end
    permute = SVector(kx, ky, kz)
    d = Vec3(ray.direction[permute])
    p0t = Vec3(p0t[permute])
    p1t = Vec3(p1t[permute])
    p2t = Vec3(p2t[permute])
    Sx = -d.x / d.z
    Sy = -d.y / d.z
    Sz =  1.0 / d.z
    p0t = Vec3(p0t.x + Sx * p0t.z, p0t.y + Sy * p0t.z, p0t.z)
    p1t = Vec3(p1t.x + Sx * p1t.z, p1t.y + Sy * p1t.z, p1t.z)
    p2t = Vec3(p2t.x + Sx * p2t.z, p2t.y + Sy * p2t.z, p2t.z)

    ## compute edge function
    e0 = p1t.x * p2t.y - p1t.y * p2t.x
    e1 = p2t.x * p0t.y - p2t.y * p0t.x
    e2 = p0t.x * p1t.y - p0t.y * p1t.x
    
    ## fall back to double precision
    # TODO

    ## perform edge & det tests
    if (e0 < 0 || e1 < 0 || e2 < 0) && (e0 > 0 || e1 > 0 || e2 > 0)
        return false, 0.0, empty_surface_interation(tri)
    end
    det = e0 + e1 + e2
    if det == 0
        return false, 0.0, empty_surface_interation(tri)
    end

    ## compute scaled sitance to triangle and test against rayt
    p0t = Vec3(p0t.x, p0t.y, p0t.z * Sz)
    p1t = Vec3(p1t.x, p1t.y, p1t.z * Sz)
    p2t = Vec3(p2t.x, p2t.y, p2t.z * Sz)
    t_scaled = e0 * p0t.z + e1 * p1t.z + e2 * p2t.z
    if (det < 0 && (t_scaled >= 0 || t_scaled < ray.tMax * det))
        return false, 0.0, empty_surface_interation(tri)
    end
    if (det > 0 && (t_scaled <= 0 || t_scaled > ray.tMax * det))
        return false, 0.0, empty_surface_interation(tri)
    end

    ## compute barycentric coords and t for intesection
    inv_det = 1 / det
    b0 = e0 * inv_det
    b1 = e1 * inv_det
    b2 = e2 * inv_det
    t = t_scaled * inv_det

    # Compute triangle partial derivatives
    uv = get_uvs(tri)
    duv13 = uv[1] - uv[3]
    duv23 = uv[2] - uv[3]
    dp13 = p0 - p2
    dp23 = p1  - p2
    determinate = duv13[1] * duv23[2] - duv13[2] * duv23[1]
    degenerateUV = abs(determinate) < 1e-8
    if !degenerateUV
        invdet = 1.0/determinate
        dpdu = Vec3(( duv23[2]*dp13 - duv13[2]*dp23) * inv_det)
        dpdv = Vec3((-duv23[1]*dp13 + duv13[1]*dp23) * inv_det)
    end
    if degenerateUV || norm(cross(dpdu, dpdv))^2==0
        # Handle zero determinant for triangle partial derivative matrix
        ng = cross(p2 - p0, p1 - p0)
        if norm(ng)^2 == 0
            return false, 0.0, empty_surface_interation(tri)
        end
        _, dpu, dpv = orthonormal_basis(Vec3(ng))
        dpdu = Vec3(dpu)
        dpdv = Vec3(dpv)
    end
    @info "TRIANGLE: dpdu=$(dpdu), dpdv=$(dpdv)"

    # interpolate uv coords and hit point
    phit = b0 * p0 + b1 * p1 + b2 * p2
    uvhit = b0 * uv[1] + b1 * uv[2] + b2 * uv[3]

    # Test intersection against alpha texture, if present
    if !(tri.mesh.alpha_mask isa Nothing)
        si = InstantiateSurfaceInteraction(
                phit,
                0.0,
                Vec3(1,1,1),
                uvhit,
                Vec3(1,1,1),
                Vec3(1,1,1),
                Nml3(1,1,1),
                Nml3(1,1,1),
                tri,
                nothing,
                nothing
            )
        if tri.mesh.alpha_mask(si) == spectrum_from_float(1, 1, 1)
            return false, 0.0, si
        end
    end

    # Fill in _SurfaceInteraction_ from triangle hit
    interaction = InstantiateSurfaceInteraction(phit, ray.t, -ray.direction, uvhit, dpdu, dpdv, Nml3(0,0,0), Nml3(0,0,0), tri)

    # Override surface normal in _isect_ for triangle
    interaction.core.n = interaction.shading.n = Nml3(normalize(cross(dp13, dp23)))
    @info "Original normal: $(interaction.core.n)"
    if tri.core.reverse_orientation ⊻ tri.core.transform_swaps_handedness
        @info "FLIPPED NORMAL"
        interaction.core.n = interaction.shading.n = -interaction.core.n    
    end

    # TODO making shading tangents real
    # TODO JOHN HACK FOR NORMAL FLAG
    normal_flag = sum(sum.(tri.mesh.normals)) == 0.0
    if !(normal_flag) || !(tri.mesh.shading_tangent isa Nothing)
        # Initialize _Triangle_ shading geometry

        # Compute shading normal _ns_ for triangle
        if !(tri.mesh.normals isa Nothing)
            n1, n2, n3 = get_normals(tri)
            ns = normalize(
                b0 * n1 + b1 * n2 + b2 * n3
            )
            if norm(ns)^2 > 0
                ns = normalize(ns)
            else
                ns = interaction.core.n
            end
        else
            ns = interaction.core.n
        end

        # Compute shading tangent _ss_ for triangle
        if !(tri.mesh.shading_tangent isa Nothing)
            s1, s2, s3 = get_shading_tangents(tri)
            ss = b0 * s1 + b1 * s2 + b2 * s3
            if norm(ss)^2 > 0 
                ss = normalize(ss)
            else
                ss = normalize(interaction.dpdu)
            end
        else
            ss = normalize(interaction.dpdu)
        end

        # Compute shading bitangent _ts_ for triangle and adjust _ss_
        ts = cross(ss, ns)
        @info "TRIANGLE: ts=$(ts), ss=$(ss), ns=$(ns)"
        if length_squared(ts) > 0.0
            ts = normalize(ts)
            ss = cross(ts, ns)
        else
            _, ss, ts = orthonormal_basis(Vec3(ns))
        end
        @info "TRIANGLE AGAIN: ts=$(ts), ss=$(ss), ns=$(ns)"

        # Compute $\dndu$ and $\dndv$ for triangle shading geometry
        if !(tri.mesh.normals isa Nothing)
            n1, n2, n3 = get_normals(tri)
            # Compute deltas for triangle partial derivatives of normal
            duv02 = uv[1] - uv[3]
            duv12 = uv[2] - uv[3]
            dn1 = n1 - n3
            dn2 = n2 - n3
            determinant = duv02[1] * duv12[2] - duv02[2] * duv12[1]
            degenerateUV = abs(determinant) < 1e-8
            if degenerateUV
                dn = cross(
                    Vec3(n3-n1),
                    Vec3(n2-n1)
                )
                if norm(dn)^2 == 0
                    dndu = dndv = Nml3(0,0,0)
                else
                    _, dnu, dnv = orthonormal_basis(dn)
                    dndu = Nml3(dnu)
                    dndv = Nml3(dnv)
                end
            else
                inv_det = 1 / determinant
                dndu = (duv12[2] * dn1 - duv02[2] * dn2) * inv_det
                dndv = (-duv12[1] * dn1 + duv02[1] * dn2) * inv_det
            end
        else
            dndu = dndv = Nml3(0,0,0)
        end
        if tri.core.reverse_orientation
            ts = -ts
        end
        set_shading_geomerty!(interaction, ss, ts, dndu, dndv, true)
    end
    return true, t, interaction 
end

function intersect_p(tri::Triangle, ray::AbstractRay, ::Bool=false)::Bool
    # get triangle vertices
    p0, p1, p2 = get_vertices(tri)
    
    # perform ray-triangle intersection test
    ## transform vertices to ray coord space
    p0t = Pnt3(p0 - Vec3(ray.origin))
    p1t = Pnt3(p1 - Vec3(ray.origin))
    p2t = Pnt3(p2 - Vec3(ray.origin))
    kz = argmax(abs.(ray.direction))
    kx = kz + 1
    if kx == 4
        kx = 1
    end
    ky = kx + 1
    if ky == 4
        ky = 1
    end
    permute = SVector(kx, ky, kz)
    d = Vec3(ray.direction[permute])
    p0t = Vec3(p0t[permute])
    p1t = Vec3(p1t[permute])
    p2t = Vec3(p2t[permute])
    Sx = -d.x / d.z
    Sy = -d.y / d.z
    Sz =  1.0 / d.z
    p0t = Vec3(p0t.x + Sx * p0t.z, p0t.y + Sy * p0t.z, p0t.z)
    p1t = Vec3(p1t.x + Sx * p1t.z, p1t.y + Sy * p1t.z, p1t.z)
    p2t = Vec3(p2t.x + Sx * p2t.z, p2t.y + Sy * p2t.z, p2t.z)

    ## compute edge function
    e0 = p1t.x * p2t.y - p1t.y * p2t.x
    e1 = p2t.x * p0t.y - p2t.y * p0t.x
    e2 = p0t.x * p1t.y - p0t.y * p1t.x
    
    ## fall back to double precision
    # TODO

    ## perform edge & det tests
    if (e0 < 0 || e1 < 0 || e2 < 0) && (e0 > 0 || e1 > 0 || e2 > 0)
        return false
    end
    det = e0 + e1 + e2
    if det == 0
        return false
    end

    ## compute scaled sitance to triangle and test against rayt
    p0t = Vec3(p0t.x, p0t.y, p0t.z * Sz)
    p1t = Vec3(p1t.x, p1t.y, p1t.z * Sz)
    p2t = Vec3(p2t.x, p2t.y, p2t.z * Sz)
    t_scaled = e0 * p0t.z + e1 * p1t.z + e2 * p2t.z
    if (det < 0 && (t_scaled >= 0 || t_scaled < ray.tMax * det))
        return false
    end
    if (det > 0 && (t_scaled <= 0 || t_scaled > ray.tMax * det))
        return false
    end

    return true
end

function area(tri::Triangle)::Float64
    p0, p1, p2 = tri.core.world_to_object.(get_vertices(tri))
    c = cross(p1 - p0, p2 - p0)
    return 0.5 * sqrt(dot(c, c))
end

# non-spherical angle sampling
function sample(tri::Triangle, u::Pnt2)::Tuple{Pnt3, Nml3}
    su0 = sqrt(u[1])
    b = Pnt2(1 - su0, u[2] * su0)
    p0, p1, p2 = get_vertices(tri)
    p = b[1] * p0 + b[2] * p1 + (1-b[1]-b[2]) * p2
    n = normalize(Vec3(cross(p1-p0, p2-p0)))

    if !(tri.mesh.normals isa Nothing)
        n1, n2, n3 = get_normals(tri)
        ns = b[1] * n1 + b[2] * n2  + (1-b[1]-b[2]) * n3
        n = face_forward(n,ns)
        # MORE JOHN HACKS
        if tri.core.reverse_orientation
            n = -n
        end
    elseif tri.core.reverse_orientation ⊻ tri.core.transform_swaps_handedness
        n = -n
    end
    
    return p, n
end

function spherical_triangle_area(a::Pnt3, b::Pnt3, c::Pnt3)::Float64
    return abs(2.0 * atan(
        dot(a, cross(b, c)),
        1.0 + dot(a, b) + dot(a, c) + dot(b, c)
    ))
end

function solid_angle(p0::Pnt3, p1::Pnt3, p2::Pnt3, p::Pnt3)::Float64
    return spherical_triangle_area(
        normalize(p0 - p),
        normalize(p1 - p),
        normalize(p2 - p)
    )
end

function sample(tri::Triangle, intr::Interaction, u::Pnt2)::Tuple{Pnt3, Nml3}
    # not defining global vars...
    min_spherical_sample_area=3e-4
    max_spherical_sample_area=6.22

    # Get triangle vertices in _p0_, _p1_, and _p2_
    p0, p1, p2 = get_vertices(tri)

    # Use uniform area sampling for numerically unstable cases
    solid_angle_val = solid_angle(p0, p1, p2, intr.p)

    if (solid_angle_val < min_spherical_sample_area) || (solid_angle_val > max_spherical_sample_area)
        # Sample shape by area and compute incident direction _wi_
        return sample(tri, u)
    end

    # Sample spherical triangle from reference point
    # Apply warp product sampling for cosine factor at reference point
    pdf_val = 1.0
    if intr.n != Nml3(0, 0, 0)
        # Compute $\cos\theta$-based weights _w_ at sample domain corners
        rp = intr.p
        # wi = Vec3(, , )
        w = Vec4(
            max(.01, abs(dot(intr.n, normalize(p1 - rp)))),
            max(.01, abs(dot(intr.n, normalize(p1 - rp)))),
            max(.01, abs(dot(intr.n, normalize(p0 - rp)))),
            max(.01, abs(dot(intr.n, normalize(p2 - rp))))
        )
        u = sample_bilinear(u, w)
        @assert (u[1] >= 0.0) && (u[1] < 1.0) && (u[2] >= 0.0) && (u[2] < 1.0)
        pdf_val = bilinear_pdf(u, w)
    end
    b, tri_pdf = sample_spherical_triangle(p0, p1, p2, intr.p, u)
    # TODO what if pdf 0?
    if tri_pdf == 0.0
        return Pnt3(0,0,0), Nml3(0,0,0)
    end
    pdf_val *= tri_pdf

    # Return _ShapeSample_ for solid angle sampled point on triangle
    p = b[1] * p0 + b[2] * p1 + b[3] * p2
    # Compute surface normal for sampled point on triangle
    n = normalize(Nml3(cross(p1 - p0, p2 - p0)))
    if !(tri.mesh.normals isa Nothing)
        n0, n1, n2 = get_normals(tri)
        ns = b[1] * n0 + b[2] * n1 + (1.0 - b[1] - b[2]) * n2
        n = face_forward(n, ns)
    elseif tri.core.reverse_orientation ⊻ tri.core.transform_swaps_handedness
        n *= -1.0
    end
    return p, n
end
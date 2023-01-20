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
function ObjectBounds(tri::Triangle)::Bounds3
    # TODO
    # triangles have their vertices already in world space so go backwards because
    # results of this function are transformed back
    # ugh
    p0, p1, p2 = tri.core.world_to_object.(get_vertices(tri))
    # TODO why must I do this
    buffer = (p0 .== p1 .==  p2) .* .0001
    return world_bounds(world_bounds(Bounds3(p0-buffer, p0+buffer), Bounds3(p1-buffer, p1+buffer)), Bounds3(p2-buffer, p2+buffer))
end

##############################
####### Helper Functions #####
##############################

@inline function get_vertices(t::Triangle)::Tuple{Pnt3, Pnt3, Pnt3}
    return t.mesh.vertices[t.mesh.indices[t.i]], t.mesh.vertices[t.mesh.indices[t.i + 1]], t.mesh.vertices[t.mesh.indices[t.i + 2]]
end

@inline function get_normals(t::Triangle)::Tuple{Nml3, Nml3, Nml3}
    # TODO implement ability to NOT have normals
    return t.mesh.normals[t.mesh.indices[t.i]], t.mesh.normals[t.mesh.indices[t.i + 1]], t.mesh.normals[t.mesh.indices[t.i + 2]]
end

@inline function get_uvs(t::Triangle)::Tuple{Pnt2, Pnt2, Pnt2}
    # TODO implement UVS
    return Pnt2(0, 0), Pnt2(1,0), Pnt2(1,1)
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
    p0t = p0 - ray.origin
    p1t = p1 - ray.origin
    p2t = p2 - ray.origin
    kz = argmax(abs.(ray.direction))
    kx = kz + 1
    kx == 4 && (kx = 1)
    ky = kx + 1
    ky == 4 && (ky = 1)

    permute = SVector(kx, ky, kz)
    d = ray.direction[permute]
    p0t = p0t[permute]
    p1t = p1t[permute]
    p2t = p2t[permute]
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
    (e0 < 0 || e1 < 0 || e2 < 0) && (e0 > 0 || e1 > 0 || e2 > 0) && (return false, nothing, nothing)
    det = e0 + e1 + e2
    det == 0 && (return false, nothing, nothing)

    ## compute scaled sitance to triangle and test against rayt
    p0t = Vec3(p0t.x, p0t.y, p0t.z * Sz)
    p1t = Vec3(p1t.x, p1t.y, p1t.z * Sz)
    p2t = Vec3(p2t.x, p2t.y, p2t.z * Sz)
    t_scaled = e0 * p0t.z + e1 * p1t.z + e2 * p2t.z
    (det < 0 && (t_scaled >= 0 || t_scaled < ray.tMax * det)) && (return false, nothing, nothing)
    (det > 0 && (t_scaled <= 0 || t_scaled > ray.tMax * det)) && (return false, nothing, nothing)

    ## compute barycentric coords and t for intesection
    inv_det = 1 / det
    b0 = e0 * inv_det
    b1 = e1 * inv_det
    b2 = e2 * inv_det
    t = t_scaled * inv_det

    # compute partials
    uv1, uv2, uv3 = get_uvs(tri)
    duv13 = uv1 - uv3
    duv23 = uv2 - uv3
    dp13 = p0 - p2
    dp23 = p1  - p2
    determinate = duv13.x * duv23.y - duv13.y * duv23.x
    if determinate == 0
        v = normalize(cross(p2-p0, p1-p0))
        _, dpdu, dpdv = orthonormal_basis(v)
    else
        inv_determinate = 1 / determinate
        dpdu = duv23[2] * dp13 - duv13[2] * dp23 * inv_determinate
        dpdv = -duv23[1] * dp13 + duv13[1] * dp23 * inv_determinate
    end

    # interpolate uv coords and hit point
    phit = b0 * p0 + b1 * p1 + b2 * p2
    uvhit = b0 * uv1 + b1 * uv2 + b2 * uv3

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
        if tri.mesh.alpha_mask(si) == Spectrum(1, 1, 1)
            return false, 0.0, si
        end
    end

    # Fill in _SurfaceInteraction_ from triangle hit
    interaction = InstantiateSurfaceInteraction(phit, ray.t, -ray.direction, uvhit, dpdu, dpdv, Nml3(0,0,0), Nml3(0,0,0), tri)

    dn13 = n1 - n3
    dn23 = n2 - n3
    if determinate == 0
        dndu = Nml3(0,0,0)
        dndv = Nml3(0,0,0)
    else
        dndu = duv23[2] * dn13 - duv13[2] * dn23 * inv_determinate
        dndv = -duv23[1] * dn13 + duv13[1] * dn23 * inv_determinate
    end

    # fill interaction
    interaction = InstantiateSurfaceInteraction(phit, ray.time, -ray.direction, uvhit, Vec3(dpdu), Vec3(dpdv), Nml3(dndu), Nml3(dndv), tri)
    interaction.core.n = normalize(cross(dp13, dp23))   
    interaction.shading.n = cross(ss, ts)
    interaction.shading.dpdu = ss
    interaction.shading.dpdv = ts
    interaction.shading.dndu = dndu
    interaction.shading.dndv = dndv

    if tri.mesh.normals ≢ nothing
        interaction.core.n = face_forward(
            interaction.core.n, interaction.shading.n,
        )
    elseif tri.core.reverse_orientation ⊻ tri.core.transform_swaps_handedness
        interaction.core.n = interaction.shading.n = -interaction.core.n
    end

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
    if norm(ts)^2 > 0
        ts = normalize(ts)
        ss = cross(ts, ns)
    else
        _, ss, ts = orthonormal_basis(Vec3(ns))
    end

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
    # print("here \n")
    # print("ss: ", ss, "\n")
    # print("ss: ", ts, "\n")
    # print("cross: ", cross(ss, ts), "\n")
    # print("n: ", interaction.core.n, "\n")
    # print("shading n: ", interaction.shading.n, "\n")
    # asdf

    # if abs(dot(interaction.core.n, interaction.shading.n)) == 0
    #     print(interaction.core.n, "\n")
    #     print(interaction.shading.n, "\n")
    # end
    return true, t, interaction 
end

function intersect_p(tri::Triangle, ray::AbstractRay, ::Bool=false)::Bool
    # get triangle vertices
    p0t, p1t, p2t = get_vertices(tri)
    
    # perform ray-triangle intersection test
    ## transform vertices to ray coord space
    p0t -= ray.origin
    p1t -= ray.origin
    p2t -= ray.origin
    kz = argmax(abs.(ray.direction))
    kx = kz + 1
    (kx == 4) && (kx = 1)
    ky = kx + 1
    ky == 4 && (ky = 1)

    permute = SVector(kx, ky, kz)
    d = ray.direction[permute]
    p0t = p0t[permute]
    p1t = p1t[permute]
    p2t = p2t[permute]
    Sx = -d.x / d.z
    Sy = -d.y / d.z
    Sz =  1.0 / d.z
    p0t = Pnt3(
        p0t.x + Sx * p0t.z,
        p0t.y + Sy * p0t.z,
        p0t.z
    )
    p1t = Pnt3(
        p1t.x + Sx * p1t.z,
        p1t.y + Sy * p1t.z,
        p1t.z
    )
    p2t = Pnt3(
        p2t.x + Sx * p2t.z,
        p2t.y + Sy * p2t.z,
        p2t.z
    )

    ## compute edge function
    e0 = p1t.x * p2t.y - p1t.y * p2t.x
    e1 = p2t.x * p0t.y - p2t.y * p0t.x
    e2 = p0t.x * p1t.y - p0t.y * p1t.x
    
    ## fall back to double precision
    # TODO JOHN: no because we live in double precision land

    ## perform edge & det tests
    (e0 < 0 || e1 < 0 || e2 < 0) && (e0 > 0 || e1 > 0 || e2 > 0) && (return false)
    det = e0 + e1 + e2
    (det == 0) && (return false)

    ## compute scaled sitance to triangle and test against rayt
    t_scaled = e0 * p0t.z * Sz + e1 * p1t.z * Sz + e2 * p2t.z * Sz
    (det < 0 && (t_scaled >= 0 || t_scaled < ray.tMax * det)) && (return false)
    (det > 0 && (t_scaled <= 0 || t_scaled > ray.tMax * det)) && (return false)

    return true
end

# MT algorithm for comparison purposes
function intersect_p_MT(tri::Triangle, ray::AbstractRay, ::Bool=false)::Bool
    # get triangle vertices
    p0, p1, p2 = get_vertices(tri)

    p0p1 = p1 - p0
    p0p2 = p2 - p0
    pvec = cross(r.direction, p0p2)
    det = dot(p0p1, pvec)

    det < 0.000001 && (return false)

    inv_det = 1.0 / det
    tvec = r.origin - p0
    u = dot(tvec, pvec) * inv_det
    (u < 0) || (u > 1) && (return false)

    qvec = cross(tvec, p0p1)
    v = dot(r.direction, qvec) * inv_det
    (v < 0) || (u + v > 1) && (return false)

    return true
end

function area(tri::Triangle)::Float64
    p0, p1, p2 = tri.core.world_to_object.(get_vertices(tri))
    return 0.5 * length(cross(p1-p0, p2-p0))
end

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
function sample(tri::Triangle, interaction::Interaction, u::Pnt2)::Tuple{Pnt3, Nml3}
    return sample(tri, u)
end
struct TriangleMesh
    n_triangles::Int64
    n_vertices::Int64
    vertices::Vector{Pnt3}
    indices::Vector{Int64}
    normals::Vector{Nml3}

    function TriangleMesh(object_to_world::Transformation, n_triangles::Int64, n_vertices::Int64, vertices::Vector{Pnt3}, indices::Vector{Int64}, normals::Vector{Nml3})
        vertices = object_to_world.(vertices)
        new(n_triangles, n_vertices, vertices, indices)
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
#### Get Bounds Working ###########################
###################################################

# PBR 3.6.1
# "The Triangle shape is one of the shapes that can compute a better world space bound than can be found by transforming its 
# object space bounding box to world space. Its world space bound can be directly computed from the world space vertices."
function ObjectBounds(tri::Triangle)
    p0, p1, p2 = get_vertices(tri)
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

function get_vertices(t::Triangle)
    return Pnt3[t.mesh.vertices[t.mesh.indices[t.i + j]] for j in 0:2]
end

function get_uvs(t::Triangle)
    # TODO implement UVS
    # if t.mesh.uv isa Nothing
    #     return [Pnt2(0, 0), Pnt2(1,0), Pnt2(1,1)]
    # else
    #     return [t.mesh.uv[t.i + j] for j in 0:2]
    # end
    return return [Pnt2(0, 0), Pnt2(1,0), Pnt2(1,1)]
end

###################################################
###### Instantiate a triangle mesh manually #######
###################################################

function construct_triangle_mesh(core::ShapeCore, n_triangles::Int64, n_vertices::Int64, vertices::Vector{Pnt3}, indices::Vector{Int64}, normals::Vector{Nml3})
    mesh = TriangleMesh(core.object_to_world, n_triangles, n_vertices, vertices, indices, normals)
    return [Triangle(core, mesh, i) for i in 0:(n_triangles-1)]
end

##################################################
######### Intersect ##############################
##################################################

# PBR 3.6.2
function Intersect(tri::Triangle, ray::Ray, ::Bool=false)::Tuple{Bool, Maybe{Float64}, Maybe{SurfaceInteraction}}
    # get triangle vertices
    p0, p1, p2 = get_vertices(tri)
    
    # perform ray-triangle intersection test
    ## transform vertices to ray coord space
    p0t = p0 - Vec3(ray.origin)
    p1t = p1 - Vec3(ray.origin)
    p2t = p2 - Vec3(ray.origin)
    kz = argmax(abs.(ray.direction))
    kx = kz + 1
    if kx == 4
        kx = 1
    end
    ky = kx + 1
    if ky == 4
        ky = 1
    end
    permute = [kx, ky, kz]
    d = Vec3(ray.direction[permute])
    # p0t = Vec3(p0t[permute])
    # p1t = Vec3(p1t[permute])
    # p2t = Vec3(p2t[permute])
    # Sx = -d.x / d.z
    # Sy = -d.y / d.z
    # Sz =  1.0 / d.z
    # p0t = Vec3(p0t.x * Sx * p0t.z, p0t.y * Sy * p0t.z, p0t.z)
    # p1t = Vec3(p1t.x * Sx * p1t.z, p1t.y * Sy * p1t.z, p1t.z)
    # p2t = Vec3(p2t.x * Sx * p2t.z, p2t.y * Sy * p2t.z, p2t.z)

    # WHAT
    denom = 1.0 / d[3]
    shear = Pnt3(-d[1] * denom, -d[2] * denom, denom)
    p0t = (p0 - ray.origin)[permute] + Pnt3(shear[1]*(p0[kz] - ray.origin[kz]), shear[2]*(p0[kz] - ray.origin[kz]), 0)
    p1t = (p1 - ray.origin)[permute] + Pnt3(shear[1]*(p1[kz] - ray.origin[kz]), shear[2]*(p1[kz] - ray.origin[kz]), 0)
    p2t = (p2 - ray.origin)[permute] + Pnt3(shear[1]*(p2[kz] - ray.origin[kz]), shear[2]*(p2[kz] - ray.origin[kz]), 0)


    ## compute edge function
    e0 = p1t.x * p2t.y - p1t.y * p2t.x
    e1 = p2t.x * p0t.y - p2t.y * p0t.x
    e2 = p0t.x * p1t.y - p0t.y * p1t.x
    
    ## fall back to double precision
    # TODO

    ## perform edge & det tests
    if (e0 < 0 || e1 < 0 || e2 < 0) && (e0 > 0 || e1 > 0 || e2 > 0)
        return false, nothing, nothing
    end
    det = e0 + e1 + e2
    if det == 0
        return false, nothing, nothing
    end

    ## compute scaled sitance to triangle and test against rayt
    p0t = Vec3(p0t.x, p0t.y, p0t.z * denom)
    p1t = Vec3(p1t.x, p1t.y, p1t.z * denom)
    p2t = Vec3(p2t.x, p2t.y, p2t.z * denom)
    t_scaled = e0 * p0t.z + e1 * p1t.z + e2 * p2t.z
    if (det < 0 && (t_scaled >= 0 || t_scaled < ray.tMax * det))
        return false, nothing, nothing
    end
    if (det > 0 && (t_scaled <= 0 || t_scaled > ray.tMax * det))
        return false, nothing, nothing
    end

    ## compute barycentric coords and t for intesection
    inv_det = 1 / det
    b0 = e0 * inv_det
    b1 = e1 * inv_det
    b2 = e2 * inv_det
    t = t_scaled * inv_det

    # compute partials
    uv = get_uvs(tri)
    duv13 = uv[1] - uv[3]
    duv23 = uv[2] - uv[3]
    dp13 = p0 - p2
    dp23 = p1  - p2
    determinate = duv13[1] * duv23[2] - duv13[2] * duv23[1]
    if determinate == 0
        v = normalize(cross(p2-p0, p1-p0))
        if abs(v[1]) > abs(v[2])
            dpdu = Vec3(-v.z, 0, v.x) / sqrt(v.x * v.x + v.z * v.z)
        else
            dpdu = Vec3(0, v.z, -v.y) / sqrt(v.y * v.y + v.z * v.z)
        end
        dpdv = cross(v,dpdu)
    else
        inv_determinate = 1 / determinate
        dpdu = Vec3(duv23[2] * dp13 - duv13[2] * dp23) * inv_determinate
        dpdv = Vec3(-duv23[1] * dp13 + duv13[1] * dp23) * inv_determinate
    end

    # interpolate uv coords and hit point
    phit = b0 * p0 + b1 * p1 + b2 * p2
    uvhit = b0 * uv[1] + b1 * uv[2] + b2 * uv[3]

    # fill interaction
    interaction = InstantiateSurfaceInteraction(phit, ray.time, -ray.direction, uvhit, dpdu, dpdv, Nml3(0,0,0), Nml3(0,0,0), tri)
    interaction.core.n = interaction.shading.n = normalize(cross(dp13, dp23))

    # TODO
    # shading geometry and normals here

    return true, t, interaction
end


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
    p0, p1, p2 = vertices(tri)
    return world_bounds(world_bounds(Bounds3(p0, p0), Bounds3(p1, p1)), Bounds3(p2, p2))
end

##############################
####### Helper Functions #####
##############################

function vertices(t::Triangle)
    return Pnt3[t.mesh.vertices[t.mesh.indices[t.i + j]] for j in 0:2]
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
function intersect(tri::Triangle, ray::Ray, ::Bool=false)::Tuple{Bool, Maybe{Float64}, Maybe{SurfaceInteraction}}
    # get triangle vertices
    p0, p1, p2 = vertices(tri)

    # perform ray-triangle intersection test
    ## transform vertices to ray coord space
    p0t = p0 - Vec3(ray.origin)
    p1t = p1 - Vec3(ray.origin)
    p2t = p2 - Vec3(ray.origin)
    kz = argmax(abs(ray.direction))
    kx = kz + 1
    if kx == 4
        kz = 1
    end
    ky = kx + 1
    if ky == 4
        ky = 1
    end
    permute = [kx, ky, kz]
    d = ray.direction[permute]
    p0t = p0t[permute]
    p1t = p1t[permute]
    p2t = p2t[permute]
    Sx = -d.x / d.z
    Sy = -d.y / d.z
    Sz = 1 / d.z
    p0t = Vec3(p0t.x * Sx, p0t.y * Sy, p0t.z)
    p1t = Vec3(p1t.x * Sx, p1t.y * Sy, p1t.z)
    p2t = Vec3(p2t.x * Sx, p2t.y * Sy, p2t.z)

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
    p0t = Vec3(p0t.x, p0t.y, p0t.z * Sz)
    p1t = Vec3(p1t.x, p1t.y, p1t.z * Sz)
    p2t = Vec3(p2t.x, p2t.y, p2t.z * Sz)
    t_scaled = e0 * p0t.z + e1 * p1t.z + e2 * p2t.z
    if det < 0 && (t_scaled >= 0 || t_scaled > ray.tMax * det)
        return false, nothing, nothing
    end

    inv_det = 1 / det
    b0 = e0 * inv_det
    b1 = e1 * inv_det
    b2 = e2 * inv_det
    t = t_scaled * inv_det

    ## compute barycentric coords and t for intesection

    # compute partials

    # interpolate uv coords and hit point
end


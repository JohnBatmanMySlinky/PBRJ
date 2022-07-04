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

    # perform ray-triangle intersection test

    ## transform vertices to ray coord space
    ## compute edge function
    ## fall back to double precision
    ## perform edge & det tests
    ## compute scaled sitance to triangle and test against rayt
    ## compute barycentric coords and t for intesection

    # compute partials

    # interpolate uv coords and hit point
end


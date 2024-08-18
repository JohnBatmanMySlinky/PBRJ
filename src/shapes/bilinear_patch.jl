struct BilinearPatchMesh
        n_patches::Int64
        n_vertices::Int64
        indices::Vector{Int64}
        p::Vector{Pnt3}
        n::Vector{Nml3}
        uv::Vector{Pnt2}
        alpha_mask::Maybe{Texture}
    
    function BilinearPatchMesh(
        object_to_world::Transformation,
        n_patches::Int64,
        n_vertices::Int64,
        indices::Vector{Int64},
        p::Vector{Pnt3},
        n::Vector{Nml3},
        uv::Vector{Pnt2},
        alpha_mask::Maybe{Texture},
    )
        p = object_to_world.(p)
        n = object_to_world.(n)
        return new(
            n_patches,
            n_vertices,
            indices,
            p,
            n,
            uv,
            alpha_mask
        )
        
    end
end

struct BilinearPatch <: Shape
    core::ShapeCore
    mesh::BilinearPatchMesh
    i::Int64
    area::Float64
    min_spherical_sample_area::Float64

    function BilinearPatch(core::ShapeCore, mesh::BilinearPatchMesh, i::Int64)
        # Store area of bilinear patch in area
        # Get bilinear patch vertices in p00, p01, p10, and p11
        p00 = mesh.p[mesh.indices[i+0]]
        p10 = mesh.p[mesh.indices[i+1]]
        p01 = mesh.p[mesh.indices[i+2]]
        p11 = mesh.p[mesh.indices[i+3]]
        if is_rectangle(p00, p10, p10, p11)
            area = distance(p00, p01) * distance(p00, p10)
        else
            # TODO implement!
            @assert false
        end
        new(core, mesh, i*4+1, area, 1e-4)
    end
end

function ObjectBounds(blp::BilinearPatch)::Bounds3
    # TODO
    # BLP have their vertices already in world space so go backwards because
    # results of this function are transformed back
    # ugh
    p00, p10, p01, p11 = blp.core.world_to_object.(get_p(blp))
    # TODO why must I do this
    buffer = Float64[0, 0, 0, 0]
    for i in 1:4
        if p00[i] == p10[i] == p01[i] == p11[i]
            buffer[i] = .0001
        end
    end
    return 
        world_bounds(
            world_bounds(
                    Bounds3(p0-buffer, p0+buffer), 
                    Bounds3(p1-buffer, p1+buffer)
                ), 
            world_bounds(
                Bounds3(p2-buffer, p2+buffer),
                Bounds3(p3-buffer, p3+buffer)
            )
        )
end

function is_rectangle(p00::Pnt3, p10::Pnt3, p01::Pnt3, p11::Pnt3)::Bool
    if (p00 == p01) || (p01 == p11) || (p11 == p10) || (p10 == p00)
        return false # cause the above implies it's a triangle!!
    end

    # Check if bilinear patch vertices are coplanar
    n = normalize(cross(p10 - p00, p01 - p00))
    if abs(dot(normalize(p11 - p00), n)) > 1e-5
        return false
    end

    # Check if planar vertices form a rectangle>> 
    p_center = Pnt3(p00 + p01 + p10 + p11) / 4.0
    d2 = Float64[
        distance_squared(p00, p_center), distance_squared(p01, p_center), 
        distance_squared(p10, p_center), distance_squared(p11, p_center)
    ]
    for i in 1:3
        if abs(d2[i+1] - d2[0+1]) / d2[0+1] > 1e-4
            return false
        end
    end
    return true
end

function area(blp::BilinearPatch)::Float64
    return blp.area
end

@inline function get_p(blp::BilinearPatch)::Tuple{Pnt3, Pnt3, Pnt3, Pnt3}
    return 
        blp.mesh.p[blp.mesh.indices[blp.i + 0]], 
        blp.mesh.p[blp.mesh.indices[blp.i + 1]], 
        blp.mesh.p[blp.mesh.indices[blp.i + 2]],
        blp.mesh.p[blp.mesh.indices[blp.i + 3]]
end
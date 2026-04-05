function voxelize_to_bounds(triangles::Vector{RayTracing.Triangle}, voxel_size::Float64; samples_per_edge=20)::Vector{Bounds3}
    # First, collect ALL voxel coordinates
    all_voxels = Set{Pnt3i}()
    
    for tri in triangles
        v0, v1, v2 = tri.vertices[1], tri.vertices[2], tri.vertices[3]
        
        for u in 0:0.05:1
            for v in 0:0.05:(1-u)
                w = 1 - u - v
                point = w*v0 + u*v1 + v*v2
                voxel_coord = Pnt3i(floor.(Int, point / voxel_size))
                push!(all_voxels, voxel_coord)
            end
        end
    end
    
    # Now only keep voxels that have at least one empty neighbor
    voxel_bounds = Bounds3[]
    neighbors = [
        (-1,0,0), (1,0,0),
        (0,-1,0), (0,1,0),
        (0,0,-1), (0,0,1)
    ]
    
    for voxel_coord in all_voxels
        # Check if any neighbor is empty
        is_surface = false
        for offset in neighbors
            neighbor = voxel_coord .+ offset
            if neighbor ∉ all_voxels
                is_surface = true
                break
            end
        end
        
        # Only create box if it's on the surface
        if is_surface
            pMin = collect(voxel_coord) .* voxel_size
            pMax = pMin .+ voxel_size
            push!(voxel_bounds, Bounds3(pMin, pMax))
        end
    end
    
    return voxel_bounds
end
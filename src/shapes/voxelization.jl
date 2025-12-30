function voxelize_to_bounds(triangles::Vector{RayTracing.Triangle}, voxel_size::Float64; samples_per_edge=20)
    voxel_bounds = RayTracing.Bounds3[]
    seen_voxels = Set{RayTracing.Pnt3}()
    
    step = 1.0 / samples_per_edge
    
    for triangle in triangles
        v0, v1, v2 = triangle.vertices[1], triangle.vertices[2], triangle.vertices[3]
        
        # Sample triangle more densely based on its size
        edge_lengths = [
            RayTracing.norm(v1 - v0),
            RayTracing.norm(v2 - v1), 
            RayTracing.norm(v0 - v2)
        ]
        max_edge = maximum(edge_lengths)
        
        # More samples for larger triangles
        local_step = min(step, voxel_size / max_edge)
        
        u = 0.0
        while u <= 1.0
            v = 0.0
            while v <= (1.0 - u)
                w = 1.0 - u - v
                point = w*v0 + u*v1 + v*v2
                
                voxel_coord = floor.(Int, point / voxel_size)
                
                if voxel_coord ∉ seen_voxels
                    push!(seen_voxels, voxel_coord)
                    
                    pMin = voxel_coord .* voxel_size
                    pMax = pMin .+ voxel_size
                    push!(voxel_bounds, RayTracing.Bounds3(pMin, pMax))
                end
                
                v += local_step
            end
            u += local_step
        end
    end
    
    return voxel_bounds
end
function recursive_pyramid_build!(
    sphere_vec::Vector{Sphere},
    tr::Transformation,
    r_vec::Vector{Float64},
    depth::Int64,
    max_depth::Int64
)
    @assert length(r_vec) == max_depth # mis-specification
    @assert length(sphere_vec) == 0 ? depth == 1 : true # first iteration must have depth == 1

    OVERLAP_FACTOR = 0.85

    if length(sphere_vec) == 0
        push!(sphere_vec, Sphere(tr, r_vec[1]))
        depth += 1
    end
   
    while depth <= max_depth
        # print("iteration: $(depth)/$(max_depth)\n")
        # print("currently we have $(length(sphere_vec)) Sphere(s) in the pyramid\n\n\n")
        for xz in Pnt2[
                Pnt2(1,1),
                Pnt2(-1,1),
                Pnt2(1, -1),
                Pnt2(-1, -1)
            ]
            height = -sqrt((r_vec[depth-1] + r_vec[depth])^2 - r_vec[depth]^2) * OVERLAP_FACTOR
            offset = Translate(Pnt3(xz.x * r_vec[depth], height, xz.y * r_vec[depth]))
            push!(sphere_vec, Sphere(tr * offset, r_vec[depth]))
            recursive_pyramid_build!(sphere_vec, tr * offset, r_vec, depth + 1, max_depth)
        end
        break
    end
end
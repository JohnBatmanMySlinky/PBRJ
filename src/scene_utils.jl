function recursive_pyramid_build!(
    sphere_vec::Vector{Sphere},
    tr::Transformation,
    r_vec::Vector{Float64},
    depth::Int64,
    max_depth::Int64
)
    @assert length(r_vec) == max_depth # mis-specification
    @assert length(sphere_vec) == 0 ? depth == 1 : true # first iteration must have depth == 1

    HEIGHT_FACTOR = 0.5
    SPREAD_FACTOR = 1.3

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
            height = -sqrt((r_vec[depth-1] + r_vec[depth])^2 - r_vec[depth]^2)
            offset = Translate(Pnt3(
                xz.x * r_vec[depth] * SPREAD_FACTOR, 
                height * HEIGHT_FACTOR, 
                xz.y * r_vec[depth] * SPREAD_FACTOR
            ))
            push!(sphere_vec, Sphere(tr * offset, r_vec[depth]))
            recursive_pyramid_build!(sphere_vec, tr * offset, r_vec, depth + 1, max_depth)
        end
        break
    end
end

function party_blob_fuckery!(input_path::String, output_path::String, replacement_color=(0.3, 0.3, 1.3))
    # Read the PNG file
    # println("Reading PNG file: $input_path")
    img = load(input_path)
    
    # Get dimensions
    # height, width = size(img)
    # println("Image dimensions: $(width)×$(height)")
    
    # Create new image for EXR
    # EXR works with floating-point values, so we'll use RGB{Float32}
    new_img = similar(img, RGB{Float32})
    
    # Create the replacement color as RGB{Float32}
    r, g, b = replacement_color
    replacement = RGB{Float32}(r, g, b)
    
    # Process each pixel
    black = RGB{Float32}(0.0, 0.0, 0.0)
    
    # println("Processing pixels...")
    for i in CartesianIndices(img)
        pixel = RGB{Float32}(convert(RGB{Float32}, img[i]))
        
        # Check if the pixel is black (allowing for small floating-point differences)
        is_black = isapprox(pixel.r, 0.0, atol=0.001) && 
                  isapprox(pixel.g, 0.0, atol=0.001) && 
                  isapprox(pixel.b, 0.0, atol=0.001)
        
        # Replace non-black pixels
        new_img[i] = is_black ? black : replacement
    end
    
    # Save as EXR
    # println("Writing EXR file: $output_path")
    OpenEXR.save(output_path, new_img)
end
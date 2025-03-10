function jmfp(fp::String)
	sys_apple = Sys.isapple()
	sys_linux = Sys.islinux()

	if !(sys_apple || sys_linux)
		print("get off windows\n")
		@assert false
	end
	
	fp_apple = occursin("Users", fp)
	fp_linux = occursin("home", fp)

	if !(fp_apple || fp_linux)
		print("bad input string\n")
		@assert false
	end
	

	if fp_apple && sys_linux
		fp = replace(fp, "Users" => "home")
		fp = replace(fp, "johnmyslinski" => "jmyslinski")
		fp = replace(fp, "Documents" => "random_stuff")
	elseif fp_linux && sys_apple
		fp = replace(fp, "home" => "Users")
		fp = replace(fp, "jmyslinski" => "johnmyslinski")
		fp = replace(fp, "random_stuff" => "Documents")
	end
	return fp
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
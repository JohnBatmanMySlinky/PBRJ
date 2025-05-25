using Images
using FileIO
using Statistics

function calculate_rmse(img1, img2)
    # Convert images to float arrays for calculation
    arr1 = Float64.(channelview(img1))
    arr2 = Float64.(channelview(img2))
    
    # Calculate squared differences
    squared_diff = (arr1 .- arr2).^2
    
    # Calculate mean squared error
    mse = mean(squared_diff)
    
    # Calculate RMSE
    rmse = sqrt(mse)
    
    return rmse
end

function main()
    # Check if correct number of arguments provided
    if length(ARGS) != 2
        println("Usage: julia compare_images.jl <path_to_image1.png> <path_to_image2.png>")
        exit(1)
    end
    
    # Get file paths from command line arguments
    file1 = ARGS[1]
    file2 = ARGS[2]
    
    # Check if files exist
    if !isfile(file1) || !isfile(file2)
        println("Error: One or both image files do not exist.")
        exit(1)
    end
    
    # Load images
    try
        img1 = load(file1)
        img2 = load(file2)
        
        # Check if images are the same size
        if size(img1) != size(img2)
            println("Error: Images must be the same size.")
            exit(1)
        end
        
        # Calculate RMSE
        rmse = calculate_rmse(img1, img2)
        
        # Print result
        println("RMSE between the images: ", rmse)
        
    catch e
        println("Error loading or processing images: ", e)
        exit(1)
    end
end

# Run the main function
main()

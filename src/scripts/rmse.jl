include("../RayTracing.jl")

function main()
    # absoluate crap because RayTracing uses args so something fucky is up
    img1_path = "/home/jmyslinski/random_stuff/PBRJ/src/ld-9-centroid-distance.exr"
    img2_path = "/home/jmyslinski/random_stuff/PBRJ/src/ld-9-power.exr"

    # Load the images
    test, test_L, test_W = RayTracing.read_image(img2_path, RayTracing.spectrum_from_float(1.0))
    baseline, baseline_L, baseline_W = RayTracing.read_image(img1_path, RayTracing.spectrum_from_float(1.0))

    # Calculate RMSE between the two images
    tot = RayTracing.spectrum_from_float(0.0)
    i = 0
    for y in 1:test_L
        for x in 1:test_W
            i += 1
            tot = tot + (test[i] - baseline[i]) .^ 2
        end
    end
    rmse = RayTracing.sqrt.(tot ./ (test_L * test_W))

    # Output the result
    print("The RMSE between the two images is: $rmse\n")
end

# Run the main function
main()
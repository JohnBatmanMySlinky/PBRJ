#!/bin/bash

# Configuration
SAMPLES_PER_PIXEL=16
SCENE_NUMBER=4
DIM=2                          # Square dimension (5x5) for testing
BASE_DIR="pixel_outputs"       # Base directory for all runs
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")  # Generate timestamp for this run
OUTPUT_DIR="$BASE_DIR/run_${TIMESTAMP}_${DIM}x${DIM}"  # Include dimension in dir name

# Create output directory structure
mkdir -p "$OUTPUT_DIR"

echo "Starting run in: $OUTPUT_DIR"

# Process each pixel
for ((y=0; y<DIM; y++)); do
    for ((x=0; x<DIM; x++)); do
        # Scale coordinates to 0-1 range for current pixel
        x_min=$(echo "scale=6; $x / $DIM" | bc)
        y_min=$(echo "scale=6; $y / $DIM" | bc)
        
        # Calculate max coordinates (next pixel)
        x_max=$(echo "scale=6; ($x + 1) / $DIM" | bc)
        y_max=$(echo "scale=6; ($y + 1) / $DIM" | bc)
        
        echo "Processing pixel ($x,$y) -> ($x_min,$y_min,$x_max,$y_max)"
        
        # Construct the command with space-separated crop window coordinates
        cmd="julia ../RayTracing.jl --scene-number $SCENE_NUMBER --image-dim $DIM --crop-window $x_min $y_min $x_max $y_max --samples-per-pixel $SAMPLES_PER_PIXEL"
        
        # Run Julia script with correct arguments
        output=$(eval "$cmd" 2>&1)
        
        # Save output and command to file
        {
            echo "$output"
            echo "---"
            echo "Command: $cmd"
            echo "---"
            echo "Pixel: $x, $y"
        } > "$OUTPUT_DIR/pixel_${x}_${y}.txt"
        
        # Optional: Add error handling
        if [ $? -ne 0 ]; then
            echo "Error processing pixel ($x,$y)" >&2
            echo "Error details: $output" >&2
        fi
    done
done

echo "Processing complete. Results in: $OUTPUT_DIR"
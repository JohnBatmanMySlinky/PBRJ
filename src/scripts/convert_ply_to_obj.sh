#!/bin/bash

# Set the directory containing PLY files
PLY_DIR="/Users/johnmyslinski/Documents/pbrt-v3-scenes/barcelona-pavilion/geometry"

# Check if the directory exists
if [ ! -d "$PLY_DIR" ]; then
    echo "Error: Directory $PLY_DIR does not exist!"
    exit 1
fi

# Path to Blender executable
BLENDER="/Applications/Blender.app/Contents/MacOS/Blender"

# Check if Blender executable exists
if [ ! -f "$BLENDER" ]; then
    echo "Error: Blender executable not found at $BLENDER"
    exit 1
fi

# Counter for processed files
COUNT=0

# Loop through each PLY file in the directory
echo "Starting PLY to OBJ conversion..."
for ply_file in "$PLY_DIR"/*.ply; do
    if [ -f "$ply_file" ]; then
        # Extract filename without extension
        filename=$(basename -- "$ply_file")
        filename_no_ext="${filename%.ply}"
        
        # Define output OBJ file path
        obj_file="$PLY_DIR/${filename_no_ext}.obj"
        
        echo "Converting: $filename"
        
        # Run Blender to convert the file
        "$BLENDER" --background --python convert_ply_to_obj.py "$ply_file" "$obj_file"
        
        # Check if conversion was successful
        if [ -f "$obj_file" ]; then
            echo "Successfully converted to: $(basename "$obj_file")"
            COUNT=$((COUNT+1))
        else
            echo "Failed to convert: $filename"
        fi
        
        echo "----------------------------------------"
    fi
done

echo "Conversion complete. Processed $COUNT files."
#!/bin/bash
# Script to iterate through sampler values and find PUSHHHHH

# Configuration
SAMPLER_FILE="/home/jmyslinski/random_stuff/pbrt-v3/src/samplers/random.cpp"
BUILD_DIR="/home/jmyslinski/random_stuff/pbrt-v3/build"  # Build directory
PBRT_EXECUTABLE="/home/jmyslinski/random_stuff/pbrt-v3/build/pbrt"
INPUT_FILE="/home/jmyslinski/random_stuff/pbrt-v3-scenes/head/head-debug.pbrt"
SEARCH_STRING="PUSHHHH"
BUILD_THREADS=16

# Check if sampler file exists
if [ ! -f "$SAMPLER_FILE" ]; then
    echo "Error: $SAMPLER_FILE not found"
    exit 1
fi

# Check if build directory exists
if [ ! -d "$BUILD_DIR" ]; then
    echo "Error: Build directory not found: $BUILD_DIR"
    exit 1
fi

# Create backup of original file
cp "$SAMPLER_FILE" "${SAMPLER_FILE}.backup"
echo "Created backup: ${SAMPLER_FILE}.backup"
echo "Build directory: $BUILD_DIR"

# Function to restore original file on exit
cleanup() {
    echo -e "\nRestoring original sampler.cpp..."
    cp "${SAMPLER_FILE}.backup" "$SAMPLER_FILE"
    echo "Cleanup complete"
}

# Set trap to restore file on script exit (including Ctrl+C)
trap cleanup EXIT

# Save current directory to return to it later
ORIGINAL_DIR=$(pwd)

# Main loop - iterate from 0.01 to 0.99 with step 0.01
for i in {1..99}; do
    # Calculate the current value
    x=$(printf "0.%02d" $i)
    
    echo "========================================="
    echo "Testing with value: ${x}f"
    echo "========================================="
    
    # ALWAYS start from the backup and replace 0.5f with current value
    cp "${SAMPLER_FILE}.backup" "$SAMPLER_FILE"
    sed -i "s/0\.5f/${x}f/g" "$SAMPLER_FILE"
    
    # Build the project (with full output)
    echo "Building with make -j${BUILD_THREADS}..."
    cd "$BUILD_DIR"
    if ! make -j${BUILD_THREADS} > /dev/null 2>&1; then
        echo "Build failed for value ${x}f"
        cd "$ORIGINAL_DIR"
        continue
    fi
    
    # Run pbrt with arguments and capture output
    echo "Running pbrt..."
    output=$("$PBRT_EXECUTABLE" --nthreads 1 "$INPUT_FILE" --logdir ./logdump/ --v 3 2>&1)
    
    # Check if output contains PUSHHHHH
    if echo "$output" | grep -q "$SEARCH_STRING"; then
        echo "✓ Found '$SEARCH_STRING' with value ${x}f!"
        echo "Output containing '$SEARCH_STRING':"
        echo "$output" | grep "$SEARCH_STRING"
        echo ""
        echo "Success! The value ${x}f produces the desired output."
        echo "The modified sampler.cpp has been preserved."
        
        # Remove trap and backup since we want to keep the successful version
        trap - EXIT
        rm "${SAMPLER_FILE}.backup"
        cd "$ORIGINAL_DIR"
        exit 0
    else
        echo "✗ '$SEARCH_STRING' not found with value ${x}f"
    fi
    
    cd "$ORIGINAL_DIR"
done

echo ""
echo "Search complete. '$SEARCH_STRING' was not found in any iteration."
echo "Original sampler.cpp has been restored."
#!/bin/bash

# Check if at least 2 arguments are provided
if [ $# -lt 2 ]; then
    echo "Usage: $0 <iterations> <command> [args...]"
    echo "Example: $0 5 julia -t 4 RayTracing.jl --scene-number 1"
    exit 1
fi

# Get number of iterations
iterations=$1
shift

# Store the command to run
command_to_run="$@"

echo "Running command $iterations times: $command_to_run"
echo "---"

# Array to store execution times
times=()

# Detect OS for timing method
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS - use gdate if available, otherwise perl
    if command -v gdate &> /dev/null; then
        USE_GDATE=true
    else
        USE_GDATE=false
    fi
else
    # Linux
    USE_GDATE=false
fi

# Function to get time in seconds with fractional part
get_time() {
    if [ "$USE_GDATE" = true ]; then
        gdate +%s.%N
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS fallback using perl
        perl -MTime::HiRes=time -e 'printf "%.6f\n", time'
    else
        # Linux
        date +%s.%N
    fi
}

# Run the command N times
for i in $(seq 1 $iterations); do
    echo "Run $i/$iterations..."
    
    start_time=$(get_time)
    
    # Run the command
    eval "$command_to_run"
    
    end_time=$(get_time)
    
    # Calculate elapsed time
    elapsed=$(echo "$end_time - $start_time" | bc)
    times+=($elapsed)
    
    echo "  Time: ${elapsed}s"
    echo ""
done

echo "=== Statistics ==="

# Calculate mean
sum=0
for time in "${times[@]}"; do
    sum=$(echo "$sum + $time" | bc)
done
mean=$(echo "scale=6; $sum / $iterations" | bc)

# Calculate standard deviation
variance_sum=0
for time in "${times[@]}"; do
    diff=$(echo "$time - $mean" | bc)
    squared=$(echo "$diff * $diff" | bc)
    variance_sum=$(echo "$variance_sum + $squared" | bc)
done
variance=$(echo "scale=6; $variance_sum / $iterations" | bc)
std_dev=$(echo "scale=6; sqrt($variance)" | bc -l)

# Print results
echo "Iterations: $iterations"
echo "Average:    ${mean}s"
echo "Std Dev:    ${std_dev}s"
echo ""
echo "Individual times:"
for i in $(seq 0 $((iterations-1))); do
    echo "  Run $((i+1)): ${times[$i]}s"
done

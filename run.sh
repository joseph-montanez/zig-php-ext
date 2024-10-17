#!/bin/bash

# Initialize variables
total=0
min=999999
max=0

# Run the command 10 times and collect the times
for i in {1..10}; do
    # Capture the real time in seconds and milliseconds (e.g., 6.009)
    result=$({ time -p ./test; } 2>&1 | grep real | awk '{print $2}')
    echo $result >> times.txt

    # Convert to float for arithmetic
    time_in_seconds=$(echo $result | awk '{print $1}')

    # Add to total
    total=$(echo "$total + $time_in_seconds" | bc)

    # Determine min and max
    if (( $(echo "$time_in_seconds < $min" | bc -l) )); then
        min=$time_in_seconds
    fi

    if (( $(echo "$time_in_seconds > $max" | bc -l) )); then
        max=$time_in_seconds
    fi
done

# Calculate average
average=$(echo "$total / 10" | bc -l)

# Display the results
echo "Execution times (seconds):"
cat times.txt
echo "Total time: $total seconds"
echo "Lowest time: $min seconds"
echo "Highest time: $max seconds"
echo "Average time: $average seconds"

# Clean up
rm times.txt

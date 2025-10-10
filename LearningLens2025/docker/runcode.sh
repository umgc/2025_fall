#!/bin/bash

# Script to run coding assignments

mkdir code_eval
cd code_eval

aws s3 cp $CODE_S3_URI ./code.zip
unzip code.zip

# Initialize empty JSON array
json="["

# Loop through each .c file
for file in *.c; do
    # Get base name (without extension)
    base=$(basename "$file" .c)
    exe="./$base.out"

    # Try to compile, capturing stderr if it fails
    if gcc "$file" -o "$exe" 2>gcc_error.log; then
        # Run program and capture stdout
        output=$("$exe" 2>&1)
        
        # Escape output safely
        escaped_output=$(echo "$output" | jq -Rs .)

        # Add success object
        json+="{\"output\":${escaped_output},\"error\":false},"
    else
        # Capture GCC error message
        error_msg=$(<gcc_error.log)

        # Escape error message safely
        escaped_error=$(echo "$error_msg" | jq -Rs .)

        # Add failure object
        json+="{\"output\":${escaped_error},\"error\":true},"
    fi

    # Clean up
    rm -f "$exe" gcc_error.log
done

# Remove trailing comma if present
json=${json%,}

# Close JSON array
json+="]"
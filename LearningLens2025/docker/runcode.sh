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

    # Compile C file
    if gcc "$file" -o "$exe"; then
        # Run program and capture output
        output=$("$exe")
        
        # Escape quotes and backslashes for JSON
        escaped_output=$(echo "$output" | jq -Rs .)

        # Append to JSON
        json+="{\"output\":${escaped_output}},"
    else
        # If compilation fails, add error message
        json+="{\"output\":\"Compilation failed for $file\"},"
    fi

    # Clean up binary
    rm -f "$exe"
done

# Remove trailing comma if present
json=${json%,}

# Close JSON array
json+="]"

# Print final JSON
echo "$json"
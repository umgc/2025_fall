#!/bin/bash

# Script to run coding assignments

mkdir code_eval
cd code_eval

aws s3 cp "$CODE_S3_URI" ./code.zip
unzip code.zip

# Initialize JSON array
json="["

# Loop over each directory in the current directory
for dir in */ ; do
    # Remove trailing slash
    dir=${dir%/}

    # Initialize per-directory outputs
    outputs="[]"
    combined_output=""
    error_occurred=false
    
    # Enter the directory
    cd "$dir" || continue

    # Loop through each .c file
    for file in *.c; do
        exe="./$(basename "$file" .c).out"

        # Compile the C file, capture stderr
        if gcc "$file" -o "$exe" 2>gcc_error.log; then
            # Run the program and capture stdout and stderr
            output=$("$exe" 2>&1)
            combined_output+="$output"
        else
            # Compilation error
            error_occurred=true
            error_msg=$(<gcc_error.log)
            combined_output+="$error_msg"
        fi

        # Clean up binary and error log
        rm -f "$exe" gcc_error.log
    done

    # Read studentId and assignmentId
    studentId=$(cat ./studentId)
    assignmentId=$(cat ./assignmentId)

    # Escape combined output and IDs for JSON
    escaped_output=$(echo -n "$combined_output" | jq -Rs .)

    # Add directory object to main JSON array
    json+="{\"output\":$escaped_output,\"studentId\":$studentId,\"assignmentId\":$assignmentId,\"error\":$error_occurred},"

    # Return to parent directory
    cd ..
done

# Remove trailing comma if present
json=${json%,}

# Close JSON array
json+="]"

# Print JSON (for logging)
echo "$json"
payload="{\"evaluation\":$json,\"assignmentId\":\"$ASSIGNMENT_ID\",\"courseId\":\"$COURSE_ID\"}"

# Invoke lambda function and print response to stdout
echo -n "$payload" | aws lambda invoke --cli-binary-format raw-in-base64-out --function-name "$LAMBDA_NAME" --payload file:///dev/stdin /dev/stdout

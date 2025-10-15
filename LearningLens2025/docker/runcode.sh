#!/bin/bash

# Script to run coding assignments
aws s3 cp "$CODE_S3_URI" ./code.zip
unzip code.zip

# Will create payload.json
python3 ./evaluate.py $LANGUAGE
ls -alh


# Invoke lambda function and print response to stdout
aws lambda invoke --cli-binary-format raw-in-base64-out \
    --function-name "$LAMBDA_NAME" \
    --payload file://payload.json /dev/stdout

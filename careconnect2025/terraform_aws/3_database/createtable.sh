#!/bin/bash
# This shell script creates the DynamoDB table required for Terraform state locking.

echo "Creating DynamoDB table 'terraform-state-lock'..."

aws dynamodb create-table \
    --table-name terraform-state-lock \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
    --region us-east-1

echo ""
read -p "Command finished. Press Enter to exit."
cd s3_tfstate || exit

echo "Formatting..."
terraform fmt --recursive

echo "Initializing..."
terraform init

echo "Planning..."
terraform plan

echo "Applying..."
terraform apply


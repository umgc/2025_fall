@echo off
 
cd s3_tfstate || exit /b

echo Initializing...
terraform init

echo Planning...
terraform plan

echo Applying...
terraform apply

echo Done. With S3 Buckets


cd ..

cd 2_general || exit /b

echo Initializing...
terraform init

echo Planning...
terraform plan

echo Applying...
terraform apply
echo Done. With 2_general

cd ..

cd 3_database || exit /b

echo Initializing...
terraform init

echo Planning...
terraform plan

echo Applying...
terraform apply
echo Done. With 3_database
cd ..

cd 4_compute || exit /b

echo Initializing...
terraform init

echo Planning...
terraform plan

echo Applying...
terraform apply

echo Done. With 4_compute

cd ..

cd 5_deploy || exit /b

echo Initializing...
terraform init

echo Planning...
terraform plan

echo Applying...
terraform apply

echo Done. With 5_deploy
# LearningLens Terraform Deployment Guide

## Prerequisites

1. AWS CLI configured with credentials
2. Terraform installed (v1.0+)
3. AWS account with appropriate permissions
4. GitHub personal access token

## Step 1: Configure AWS Profile

```bash
export AWS_PROFILE=edu
```

Or add credentials to `terraform_learninglens/environment/prod.tfvars`:
```hcl
access_key = "YOUR_AWS_ACCESS_KEY"
secret_key = "YOUR_AWS_SECRET_KEY"
```

## Step 2: Update Configuration

Edit `terraform_learninglens/environment/prod.tfvars`:

1. **GitHub Token**: Update `github_token` with your personal access token
2. **API Keys**: Add your API keys (OpenAI, Claude, etc.) to `teamA/.env`
3. **AWS Region**: Verify `aws_region = "us-east-1"`

## Step 3: Initialize Terraform

```bash
cd terraform_learninglens
terraform init
```

## Step 4: Deploy Infrastructure (First Time)

Deploy everything except Lambda (Lambda is disabled by default):

```bash
terraform apply --var-file="environment/prod.tfvars" -auto-approve
```

This creates:
- VPC with public/private subnets
- EC2 instance for Moodle
- DSQL database cluster
- S3 bucket for Lambda deployment
- Amplify app for frontend

## Step 5: Deploy Lambda Function

### 5.1 Package Lambda Code

```bash
cd ../lambda
npm install
python -m zipfile -c gettoken.zip index.mjs package.json
python -c "import zipfile, os; z = zipfile.ZipFile('gettoken.zip', 'a'); [z.write(os.path.join(root, f), os.path.join(root, f)) for root, dirs, files in os.walk('node_modules') for f in files]; z.close()"
```

### 5.2 Upload to S3

```bash
aws s3 cp gettoken.zip s3://learninglens-lambda-deployment/lambda/gettoken.zip --profile edu
```

### 5.3 Enable Lambda in Terraform

Edit `terraform_learninglens/environment/prod.tfvars`:
```hcl
lambda = {
  enabled = true  # Change from false to true
  ...
}
```

### 5.4 Deploy Lambda

```bash
cd ../terraform_learninglens
terraform apply --var-file="environment/prod.tfvars" -auto-approve
```

## Step 6: Verify Deployment

Check the following:

1. **Amplify**: Go to AWS Amplify console and verify the app is deployed
2. **Lambda**: Test the Lambda function URL
3. **DSQL**: Verify the database cluster is running
4. **EC2**: Check the Moodle instance is running

## Infrastructure Components

### Created Resources

- **VPC**: `10.1.0.0/16` with 2 public and 2 private subnets
- **EC2**: t3.small instance for Moodle (Ubuntu)
- **DSQL**: Aurora DSQL cluster for AI logging
- **S3**: Bucket for Lambda deployment packages
- **Amplify**: Flutter web app deployment
- **Lambda**: Node.js 20.x function with DSQL connection

### Environment Variables (Lambda)

The Lambda function automatically receives:
- `DSQL_ENDPOINT`: Database endpoint
- `DSQL_REGION`: AWS region
- `DSQL_CLUSTER_ARN`: Cluster ARN
- `DSQL_CLUSTER_ID`: Cluster ID
- `ENVIRONMENT`: production
- `LOG_LEVEL`: info

## Updating Infrastructure

To update any component:

```bash
cd terraform_learninglens
terraform apply --var-file="environment/prod.tfvars" -auto-approve
```

## Destroying Infrastructure

To destroy all resources:

```bash
cd terraform_learninglens
terraform destroy --var-file="environment/prod.tfvars" -auto-approve
```

## Troubleshooting

### Issue: Terraform init fails
- Check AWS credentials are configured
- Verify network connectivity

### Issue: Lambda deployment fails
- Ensure zip file is uploaded to S3
- Check S3 bucket name matches in tfvars
- Verify Lambda is enabled in tfvars

### Issue: Amplify build fails
- Check GitHub token has correct permissions
- Verify `.env` file exists in `teamA/` directory
- Check build spec in tfvars

### Issue: DSQL connection fails
- Verify IAM role has DSQL permissions
- Check VPC configuration allows DSQL access
- Ensure Lambda is in private subnet

## Important Notes

1. **Lambda must be disabled** on first deployment (S3 bucket needs to exist first)
2. **Upload Lambda zip** to S3 before enabling Lambda in Terraform
3. **GitHub token** needs repo access for Amplify
4. **DSQL endpoint** is automatically added to Lambda environment variables
5. **Outputs are commented out** to keep terminal clean - uncomment in `outputs.tf` if needed

## File Structure

```
terraform_learninglens/
├── environment/
│   └── prod.tfvars          # Production configuration
├── modules/                  # Reusable Terraform modules
│   ├── amplify/
│   ├── dsql/
│   ├── ec2/
│   ├── iam/
│   ├── lambda/
│   ├── s3/
│   ├── security_group/
│   └── vpc/
├── amplify.tf               # Amplify configuration
├── dsql.tf                  # DSQL configuration
├── ec2.tf                   # EC2 configuration
├── lambda.tf                # Lambda configuration
├── s3.tf                    # S3 configuration
├── vpc.tf                   # VPC configuration
├── main.tf                  # Main configuration
├── variables.tf             # Variable definitions
```

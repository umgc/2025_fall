# CareConnect AWS Deployment Guide

Straightforward guide to deploy CareConnect on AWS.

---

## Prerequisites

- AWS CLI configured (`aws configure`)
- Terraform >= 1.6
- Java 17 + Maven
- GitHub personal access token
- PostgreSQL client (optional, for database access)

---

## Deployment Overview

1. Configure Terraform variables
2. Deploy infrastructure (will fail on Lambda - expected)
3. Build and upload Java backend to S3
4. Update Lambda configuration
5. Verify deployment

---

## Step 1: Configure Terraform Variables

### 1.1 Create secrets.tfvars

```bash
cd careconnect2025/terraform_careconnect/environment
```

Create `secrets.tfvars`:

```hcl
# AWS Credentials
access_key = "YOUR_AWS_ACCESS_KEY"
secret_key = "YOUR_AWS_SECRET_KEY"

# GitHub Token for Amplify
github_token = "ghp_YOUR_GITHUB_TOKEN"

# Amplify Basic Auth (optional)
amplify_basic_auth_credentials = ""
```

### 1.2 Update prod.tfvars

Edit `environment/prod.tfvars`:

**Update S3 bucket name (must be globally unique):**
```hcl
s3 = {
  bucket_name = "careconnect-storage-YOUR-UNIQUE-ID"  # Change this
  # ... rest stays the same
}
```

**Update Lambda S3 bucket to match:**
```hcl
lambda = {
  # ...
  s3_bucket = "careconnect-storage-YOUR-UNIQUE-ID"  # Same as above
  s3_key    = "careconnect-backend-0.0.1-SNAPSHOT-lambda-package.zip"
  # ...
}
```

**Update CORS origins (optional):**
```hcl
lambda = {
  # ...
  cors_allowed_origins = [
    "http://localhost:3000",
    "https://your-domain.com"  # Add your domain
  ]
}
```

---

## Step 2: Initial Infrastructure Deployment

This will fail on Lambda deployment - that's expected because the JAR file doesn't exist yet.

```bash
cd careconnect2025/terraform_careconnect

# Initialize Terraform
terraform init -backend-config=backend/prod.tfvars

# Deploy infrastructure
terraform apply \
  -var-file=environment/prod.tfvars \
  -var-file=environment/secrets.tfvars
```

**Expected error:**
```
Error: Error putting S3 object: NoSuchKey: The specified key does not exist.
```

This is normal. The infrastructure (VPC, RDS, S3, API Gateway) will be created, but Lambda deployment will fail.

**Save these outputs:**
```bash
# Get S3 bucket name
terraform output s3_bucket_name

# Get RDS endpoint
terraform output rds_endpoint

# Get API Gateway URL (will be created later)
terraform output api_gateway_url
```

---

## Step 3: Build and Upload Backend

### 3.1 Build Java Application

```bash
cd ../../backend/core

# Build Spring Boot application
mvn clean package

# On Windows:
# mvnw.cmd clean package
```

This creates: `target/careconnect-backend-0.0.1-SNAPSHOT.jar`

### 3.2 Upload JAR to S3

```bash
# Upload JAR directly to S3 (replace with your bucket name from Step 2)
aws s3 cp target/careconnect-backend-0.0.1-SNAPSHOT.jar \
  s3://careconnect-storage-YOUR-UNIQUE-ID/careconnect-backend-0.0.1-SNAPSHOT-lambda-package.zip

# Verify upload
aws s3 ls s3://careconnect-storage-YOUR-UNIQUE-ID/
```

Note: We rename it to `.zip` during upload because Lambda expects that extension, but it's still just the JAR file.

---

## Step 4: Complete Lambda Deployment

Now that the JAR exists in S3, deploy Lambda:

```bash
cd ../../../terraform_careconnect

# Deploy Lambda
terraform apply \
  -var-file=environment/prod.tfvars \
  -var-file=environment/secrets.tfvars
```

This should succeed now.

**Get API Gateway URL:**
```bash
terraform output api_gateway_url
```

---

## Step 5: Configure Environment Variables

### Lambda Environment Variables

Lambda environment variables are configured in `environment/prod.tfvars` under `lambda.environment_variables`.

**Variables that use SSM Parameter Store (sensitive):**
- `JDBC_URI` → `/careconnect/prod/db/jdbc_uri`
- `DB_USER` → `/careconnect/prod/db/username`
- `DB_PASSWORD` → `/careconnect/prod/db/password`

**Variables that are direct values (non-sensitive):**
- `ENVIRONMENT` = "production"
- `LOG_LEVEL` = "INFO"
- `HIBERNATE_DDL_AUTO` = "update"
- `JWT_EXPIRATION` = "10800000"
- `SECURITY_JWT_SECRET` = "4HKbVwVyCGT1euo3FXf6Oo7dgi8HUpF9GSD3OUhzwYQ="
- `MAIL_HOST` = "smtp.sendgrid.net"
- `MAIL_PORT` = "587"
- `MAIL_SMTP_AUTH` = "true"
- `MAIL_SMTP_STARTTLS` = "true"
- `GOOGLE_SCOPE` = "openid,email,profile"
- `GOOGLE_REDIRECT_URI` = "{baseUrl}/login/oauth2/code/google"
- `GOOGLE_AUTH_URI` = "https://accounts.google.com/o/oauth2/v2/auth"
- `GOOGLE_TOKEN_URI` = "https://oauth2.googleapis.com/token"
- `GOOGLE_USERINFO_URI` = "https://www.googleapis.com/oauth2/v3/userinfo"
- `GOOGLE_CLIENT_ID` = "dummy" (update with real value)
- `GOOGLE_CLIENT_SECRET` = "dummy" (update with real value)
- `FITBIT_CLIENT_ID` = "dummy" (update with real value)
- `FITBIT_CLIENT_SECRET` = "dummy" (update with real value)
- `STRIPE_SECRET_KEY` = "" (optional)
- `OPENAI_API_KEY` = "" (optional)

**To update direct values:**
Edit `environment/prod.tfvars` and run `terraform apply`.

**To update SSM values:**
Edit `ssm.tf` and run `terraform apply`, or update directly in AWS Console.

---

## Step 6: Update SSM Parameters

The SSM parameters in `ssm.tf` have placeholder values. Update them with real credentials:

### Update Database Credentials

RDS credentials are managed by AWS (see `manage_master_user_password = true` in prod.tfvars).

```bash
# Get RDS endpoint
RDS_ENDPOINT=$(terraform output -raw rds_endpoint)

# Update JDBC URI
aws ssm put-parameter --name "/careconnect/prod/db/jdbc_uri" \
  --value "jdbc:postgresql://${RDS_ENDPOINT}:5432/careconnect" \
  --type "SecureString" \
  --overwrite

# Get RDS master password from AWS Secrets Manager
# AWS automatically stores it when manage_master_user_password = true
aws secretsmanager get-secret-value \
  --secret-id rds!db-XXXXX-XXXX-XXXX \
  --query SecretString \
  --output text

# Update SSM with the password from Secrets Manager
aws ssm put-parameter --name "/careconnect/prod/db/password" \
  --value "PASSWORD_FROM_SECRETS_MANAGER" \
  --type "SecureString" \
  --overwrite
```

**Note:** The RDS master password is automatically generated and stored in AWS Secrets Manager. Find the secret name in RDS Console > Databases > careconnect-db > Configuration > Master credentials.

### Update OAuth Credentials

```bash
# Google OAuth
aws ssm put-parameter --name "/careconnect/prod/google/client_id" \
  --value "YOUR_GOOGLE_CLIENT_ID" \
  --type "SecureString" \
  --overwrite

aws ssm put-parameter --name "/careconnect/prod/google/client_secret" \
  --value "YOUR_GOOGLE_CLIENT_SECRET" \
  --type "SecureString" \
  --overwrite

# Fitbit (optional)
aws ssm put-parameter --name "/careconnect/prod/fitbit/client_id" \
  --value "YOUR_FITBIT_CLIENT_ID" \
  --type "SecureString" \
  --overwrite

aws ssm put-parameter --name "/careconnect/prod/fitbit/client_secret" \
  --value "YOUR_FITBIT_CLIENT_SECRET" \
  --type "SecureString" \
  --overwrite
```

### Update Optional API Keys

```bash
# Stripe (if using)
aws ssm put-parameter --name "/careconnect/prod/stripe/secret_key" \
  --value "sk_test_YOUR_KEY" \
  --type "SecureString" \
  --overwrite

# OpenAI (if using)
aws ssm put-parameter --name "/careconnect/prod/openai/api_key" \
  --value "sk-YOUR_KEY" \
  --type "SecureString" \
  --overwrite
```

---

## Step 7: Configure Frontend

### 7.1 Update .env File

Edit `frontend/.env`:

```bash
cd ../../frontend
```

Update with your API Gateway URL from Step 4:

```env
CC_BASE_URL_WEB=https://YOUR_API_GATEWAY_URL
CC_BASE_URL_ANDROID=https://YOUR_API_GATEWAY_URL
CC_BASE_URL_OTHER=https://YOUR_API_GATEWAY_URL
JWT_SECRET=4HKbVwVyCGT1euo3FXf6Oo7dgi8HUpF9GSD3OUhzwYQ=
DEEPSEEK_API_KEY=
OPENAI_API_KEY=
STRIPE_PUBLISHABLE_KEY=
AGORA_APP_ID=
CC_BACKEND_TOKEN=
```

### 7.2 How Amplify Uses .env

The Amplify configuration in `amplify.tf` automatically:
1. Reads `frontend/.env` file
2. Parses each line (format: `KEY=VALUE`)
3. Sets each variable individually in Amplify environment

**You don't need to manually configure Amplify environment variables** - they're automatically loaded from `.env`.

### 7.3 Deploy Frontend

```bash
# Commit and push to trigger Amplify build
git add .env
git commit -m "Update frontend configuration"
git push origin developer
```

Amplify will automatically build and deploy. Check progress in AWS Console > Amplify.

---

## Step 8: Verify Deployment

### Test Backend

```bash
# Get API Gateway URL
API_URL=$(cd ../terraform_careconnect && terraform output -raw api_gateway_url)

# Test health endpoint
curl $API_URL/actuator/health
```

Expected response:
```json
{"status":"UP"}
```

### Test Frontend

```bash
# Get Amplify URL
AMPLIFY_URL=$(cd ../terraform_careconnect && terraform output -raw amplify_default_domain)

echo "Frontend: https://$AMPLIFY_URL"
```

Open in browser.

---

## Updating the Application

### Update Backend

```bash
# 1. Make code changes
cd backend/core

# 2. Rebuild
mvn clean package

# 3. Upload JAR to S3 (renamed to .zip)
aws s3 cp target/careconnect-backend-0.0.1-SNAPSHOT.jar \
  s3://careconnect-storage-YOUR-UNIQUE-ID/careconnect-backend-0.0.1-SNAPSHOT-lambda-package.zip \
  --region us-east-1

# 4. Update Lambda
aws lambda update-function-code \
  --function-name careconnect_main_backend \
  --s3-bucket careconnect-storage-YOUR-UNIQUE-ID \
  --s3-key careconnect-backend-0.0.1-SNAPSHOT-lambda-package.zip \
  --region us-east-1
```

### Update Frontend

```bash
# Make changes, commit, and push to developer branch
cd frontend
git add .
git commit -m "Update frontend"
git push origin developer
```

Amplify auto-deploys on push.

### Update Environment Variables

**For Lambda direct values:**
1. Edit `terraform_careconnect/environment/prod.tfvars`
2. Update values in `lambda.environment_variables`
3. Run `terraform apply`

**For SSM parameters:**
1. Edit `terraform_careconnect/ssm.tf`
2. Run `terraform apply`

Or update directly via AWS CLI (faster):
```bash
aws ssm put-parameter --name "/careconnect/prod/jwt/secret" \
  --value "NEW_VALUE" \
  --type "SecureString" \
  --overwrite
```

---

## Architecture

```
GitHub (developer branch)
    │
    └─> Amplify (Flutter Frontend)
            ├─> Reads frontend/.env
            └─> Parses into environment variables

Internet
    │
    └─> API Gateway
            │
            └─> Lambda (Java 17 Spring Boot)
                    │
                    ├─> SSM Parameter Store
                    │   ├─> Database credentials
                    │   ├─> JWT secret
                    │   └─> OAuth secrets
                    │
                    ├─> RDS PostgreSQL 16.4
                    │   └─> Private subnet
                    │
                    └─> S3 Storage
                        └─> Lambda deployment package
```

---

## Configuration Summary

### Lambda Environment Variables (prod.tfvars)

**SSM References (sensitive):**
- `JDBC_URI` → SSM
- `DB_USER` → SSM
- `DB_PASSWORD` → SSM

**Direct Values (non-sensitive):**
- `ENVIRONMENT`, `LOG_LEVEL`
- `HIBERNATE_DDL_AUTO`, `JWT_EXPIRATION`
- `SECURITY_JWT_SECRET`
- Email settings (MAIL_*)
- OAuth URIs (GOOGLE_*, FITBIT_*)
- API keys (STRIPE_*, OPENAI_*)

### SSM Parameters (ssm.tf)

**Database:**
- `/careconnect/prod/db/jdbc_uri`
- `/careconnect/prod/db/username`
- `/careconnect/prod/db/password`

**Security:**
- `/careconnect/prod/jwt/secret`
- `/careconnect/prod/config/jwt_expiration`
- `/careconnect/prod/config/hibernate_ddl_auto`

**OAuth:**
- `/careconnect/prod/google/client_id`
- `/careconnect/prod/google/client_secret`
- `/careconnect/prod/fitbit/client_id`
- `/careconnect/prod/fitbit/client_secret`

**Optional:**
- `/careconnect/prod/stripe/*`
- `/careconnect/prod/openai/*`
- `/careconnect/prod/firebase/*`
- `/careconnect/prod/agora/*`

### Frontend Environment Variables (frontend/.env)

Automatically loaded by Amplify:
- `CC_BASE_URL_WEB`
- `CC_BASE_URL_ANDROID`
- `CC_BASE_URL_OTHER`
- `JWT_SECRET`
- `DEEPSEEK_API_KEY`
- `OPENAI_API_KEY`
- `STRIPE_PUBLISHABLE_KEY`
- `AGORA_APP_ID`
- `CC_BACKEND_TOKEN`

---

## Cost Estimate

**Monthly (us-east-1):**
- RDS PostgreSQL db.t3.micro: ~$15-20
- Lambda: ~$0-5 (1M requests free tier)
- API Gateway: ~$1-3 (1M requests free tier)
- S3: ~$1-5
- Amplify: ~$0-15
- NAT Gateway: ~$32-45
- Data Transfer: Variable

**Total: ~$50-90/month**

---

## Cleanup

```bash
cd terraform_careconnect

terraform destroy \
  -var-file=environment/prod.tfvars \
  -var-file=environment/secrets.tfvars
```

---

**Last Updated:** January 2025  
**Version:** 3.0 - Simplified Deployment Guide


# Terraform for GitHub Actions to AWS OIDC Deployment

This Terraform setup creates the AWS IAM resources required to allow a GitHub Actions workflow to securely authenticate with AWS using **OpenID Connect (OIDC)** and deploy artifacts to an **S3 bucket**.

This approach avoids long-lived AWS access keys in GitHub secrets, making deployments more secure.

---

## Resources Created

### 1. IAM OpenID Connect (OIDC) Provider

* **Resource:** `aws_iam_openid_connect_provider`
* **Purpose:** Establishes a trust relationship between AWS and GitHub Actions OIDC provider.

  * One-time setup.
  * Allows AWS to verify tokens issued by GitHub.

### 2. IAM Policy

* **Resource:** `aws_iam_policy`
* **Name:** `GitHubActionsS3UploadPolicy`
* **Purpose:** Grants tightly scoped permissions:

  * `s3:PutObject` actions.
  * Limited to the folders `cc_backend_builds/` and `cc_frontend_builds/` within your S3 bucket.

### 3. IAM Role

* **Resource:** `aws_iam_role`
* **Name:** `GitHubActionsRole`
* **Purpose:** Role for GitHub Actions workflow to assume.

  * Trust policy only allows assumption by the OIDC provider.
  * Restricted to a specific **repository** and **branch** (e.g., `your-org/your-repo` and `main`).

### 4. IAM Role Policy Attachment

* **Resource:** `aws_iam_role_policy_attachment`
* **Purpose:** Attaches the `GitHubActionsS3UploadPolicy` to the `GitHubActionsRole`.
* Grants defined S3 permissions to the GitHub Actions workflow.

### 5. S3 Folder Placeholders

* **Resource:** `aws_s3_object` (two instances)
* **Purpose:** Creates empty objects in your S3 bucket with keys ending in `/`.

  * Ensures that `cc_backend_builds/` and `cc_frontend_builds/` "folders" exist before uploads.

---

## Prerequisites

Before running the Terraform code, ensure you have:

* An existing **AWS S3 bucket**.
* Terraform CLI installed.
* AWS credentials configured locally (`aws configure`).

---

## Configuration

1. Clone the repository containing the Terraform files.
2. Create a `terraform.tfvars` file in the same directory.
3. Add the following content, replacing placeholder values with your information:

```hcl
# The name of your existing S3 bucket.
s3_bucket_name = "your-actual-s3-bucket-name"

# The path to your GitHub repository in 'owner/repo' format.
github_repo = "your-github-username/your-repo-name"

# The AWS region where your S3 bucket is located.
aws_region = "us-east-1"

# The branch that will trigger deployments.
github_branch = "main"

# The folder for backend artifacts.
s3_bucket_backend_folder = "cc_backend_builds"

# The folder for frontend artifacts.
s3_bucket_frontend_folder = "cc_frontend_builds"
```

---

## How to Apply

Run the following commands in your terminal:

1. Initialize Terraform:

   ```bash
   terraform init
   ```
2. Review planned changes:

   ```bash
   terraform plan
   ```
3. Apply configuration:

   ```bash
   terraform apply
   ```

---

## Outputs

After a successful apply, Terraform will output:

* **`github_actions_role_arn`**: The full ARN of the IAM role.

Add this ARN as a secret in GitHub:

1. Go to **Repository Settings > Secrets and variables > Actions**.
2. Create a new secret named **`AWS_ROLE_ARN`**.
3. Paste the IAM role ARN value.

---

Do you want me to also write the **Terraform code snippets** (provider, role, policy, etc.) that match this setup so you can directly copy-paste into `.tf` files?

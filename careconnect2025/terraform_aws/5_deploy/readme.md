Here’s the short version in Markdown:

---

# Terraform Stack Summary

This configuration is set for GitHub Actions OIDC federation with AWS for S3 uploads. It creates:

* **OIDC provider** for `token.actions.githubusercontent.com` so GitHub could be trusted as an identity source.
* **IAM role** named `github-deploy-role` with a trust policy allowing GitHub workflows (scoped by repo/branch) to assume it.
* **Inline IAM policy** (`s3-upload-policy`) attached to that role granting permissions to upload objects into S3.

Together, these allowed GitHub Actions jobs to securely assume a role and push artifacts to S3 without long-lived AWS keys.

---

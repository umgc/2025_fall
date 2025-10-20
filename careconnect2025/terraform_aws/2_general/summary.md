
# Terraform Stack Summary

## Backend

* Uses an **S3 backend** to store Terraform state (`cc-iac-us-east-f526` bucket, encrypted, with lockfile enabled).
* Supports workspaces (hinted) to separate environments (dev, staging, prod).

## Providers

* AWS provider pinned to version `~> 5.90.0`.
* Reads AWS account identity for reference (`aws_caller_identity`).

## Modules and Resources

### Networking

* **VPC module**
  Creates the base VPC, subnets, and security groups for the environment.
  Exports identifiers like `vpc_id`, `subnet_ids`, and `main_api_sg_id`.

### Storage

* **S3 Internal module**
  Creates an S3 bucket named `cc-internal-file-storage-<region>` for internal file storage.
  Configures VPC access and IAM role permissions.

### Parameters and Secrets

* **SSM module**
  Stores application parameters (including sensitive ones) in AWS Systems Manager Parameter Store.
  Keys are dynamically generated from variables.

### Identity and Access Management

* **IAM module**
  Defines IAM roles and policies:

  * Application role (`cc_app_role_info`)
  * API Gateway role (`cc_api_gw_role`)
  * Grants access to the internal S3 bucket, Amplify app, and SSM parameters.

### Frontend Hosting

* **Amplify module**
  Sets up an AWS Amplify app and branches for hosting frontend applications.
  Tied to the IAM app role.

### Email 

* **SES module** 
  Simple Email Service integration once a domain is configured.

### APIs

* **Main API module**
  Provisions an API (likely API Gateway + Lambda backend) within the VPC.
  Uses IAM role, VPC, subnets, and security group from other modules.

### Event-Driven CI/CD

* **EventBridge module**
  Configures EventBridge rules and targets for CI/CD orchestration.
  Integrates with Amplify, S3 (for build artifacts), and Step Functions.

* **Step Function module**
  Creates a Step Functions state machine for deployment pipelines.
  Used to coordinate CI/CD workflows.

---

## TLDR

This Terraform project sets up the **core infrastructure** for an application called *CareConnect* (based on naming). It provisions a VPC, S3 storage, IAM roles, parameter storage, an Amplify frontend app, an API backend, and the scaffolding for CI/CD (EventBridge + Step Functions). SES is stubbed but not yet active.

---

 ## copy the ses_dkim_cname_records
You need this for updating CNAME records in dns provider.
eg:
ses_dkim_cname_records = {
  "leqacancledn7upayamfmetngmfkjklt._domainkey.sudnep.me" = "leqacancledn7upayamfmetngmfkjklt.dkim.amazonses.com"
  "ozbqkepjvpm5xujmhfmiuwamkjwzgeab._domainkey.sudnep.me" = "ozbqkepjvpm5xujmhfmiuwamkjwzgeab.dkim.amazonses.com"
  "vewcbow3f2akka3yujzwwuvszs6cwz7i._domainkey.sudnep.me" = "vewcbow3f2akka3yujzwwuvszs6cwz7i.dkim.amazonses.com"
}
 
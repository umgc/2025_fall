# Create the base resources for Care Connect
This will create all the base resources needed for the infrastructure of Care Connect

## Pre-requisites
1. **Make sure that you completed the list of prerequisites from [README](../README.md#pre-requisites) outside of that folder**
1. **Make sure you [Create the backend first](../s3_tfstate/README.md)** _if you did not have a bucket created previously for this._
1. **Make sure the bucket name for your s3 backend for the state is correct. It should match the name of the bucket you create in the _`s3_tfstate`_ project**
1. **Get a variable file ready to run the commands. This is needed to prevent data breach. Your variable file can look like the file below [general.tfvars](#variable-file-sample)**



## Run these commands
**Recomended**: Change directory to the `general` folder. It is better to run those commands from the folder where the `main.tf` file is.<br/>

```bash
# On Linux
cd careconnect2025/terraform_aws/general
```

```cmd
# On Windows
cd careconnect2025\terraform_aws\general
```

You can still use the `-chdir` argument if you are not running the commands from where them `main.tf` file is. [See below](#extra)

- Init
```
terraform init
```

- Plan
```
terraform plan -var-file=general.tfvars
```

- Apply
```
terraform apply -var-file=general.tfvars
```

* Type yes if you want to confirm the changes


<br>

---

### Extra
1. Use the below command to format the scripts
    ```
    terraform fmt --recursive
    ```
2. Use `-chdir` to run the command from a folder other than where the `main.tf` file is. You have to provide a path relative to where the `main.tf` file is.
    ```
    terraform -chdir=terraform_aws fmt --recursive
    ```
3. **DO NOT USE** `terraform destroy` command or else the AWS resources will be **deleted**. Unless you really what to tear down the resources you created.

4. **Useful comands**
  ```sh
  terraform state rm module.main_api.aws_apigatewayv2_vpc_link.cc_api_vpc_link # To remove a resource from a state. It would still exists in AWS. Be mindfull of cost.
  ```



### Variable file sample
*** This one below is just as an example

`general.tfvars`
``` 

domain_name = "care-connect-develop.d26kqsucj1bwc1.amplifyapp.com"

cc_ssm_params = {
  HIBERNATE_DDL_AUTO            = "update"
  JWT_EXPIRATION                = "10800000"
  MAIL_HOST                     = "smtp.sendgrid.net"
  MAIL_PORT                     = "587"
  MAIL_SMTP_AUTH                = "true"
  MAIL_SMTP_STARTTLS            = "true"
  GOOGLE_SCOPE                  = "openid,email,profile"
  GOOGLE_REDIRECT_URI           = "{baseUrl}/login/oauth2/code/google"
  GOOGLE_AUTH_URI               = "https://accounts.google.com/o/oauth2/v2/auth"
  GOOGLE_TOKEN_URI              = "https://oauth2.googleapis.com/token"
  GOOGLE_USERINFO_URI           = "https://www.googleapis.com/oauth2/v3/userinfo"
  FITBIT_CLIENT_ID     = "your_fitbit_client_id_here"
  FITBIT_CLIENT_SECRET = "your_fitbit_client_secret_here"
}

```
Save this file inside of the general folder and use it as an argument in the command lines as above.



## steps 
```
terraform init -reconfigure
```

```
terraform plan 
```
if env file is other than terraform.tfvars then you need to specify
```
terraform plan -var-file="dev.tfvars"  
```
```
terraform apply 
```
if env file is other than terraform.tfvars then you need to specify
 
```
terraform apply -var-file="dev.tfvars"
```

Here’s a concise summary of what this Terraform setup is doing and the resources it provisions:

---

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

### Email (Disabled for now)

* **SES module** (count = 0 → not deployed)
  Placeholder for Simple Email Service integration once a domain is configured.

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
You need this for updating CNAV records in dns provider.
eg:
ses_dkim_cname_records = {
  "leqacancledn7upayamfmetngmfkjklt._domainkey.sudnep.me" = "leqacancledn7upayamfmetngmfkjklt.dkim.amazonses.com"
  "ozbqkepjvpm5xujmhfmiuwamkjwzgeab._domainkey.sudnep.me" = "ozbqkepjvpm5xujmhfmiuwamkjwzgeab.dkim.amazonses.com"
  "vewcbow3f2akka3yujzwwuvszs6cwz7i._domainkey.sudnep.me" = "vewcbow3f2akka3yujzwwuvszs6cwz7i.dkim.amazonses.com"
}
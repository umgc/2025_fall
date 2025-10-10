 

## Terraform Provisioning Summary: Deployment Module

This module creates and attaches a specific **IAM Policy** that enables a CI/CD (Continuous Integration/Continuous Deployment) process for the `cc_main_backend` Lambda function. The primary goal is to allow an automated system to safely deploy new versions of the code without manual intervention.

### 1. IAM Policy for Deployment (`CcAppRoleDeploymentPolicy`)

This is the core of the module. It defines a set of specific permissions that are essential for an automated deployment workflow.

The policy grants the following abilities:

* **Lambda Function Management**:
    * `lambda:UpdateFunctionCode`: Allows the system to upload a new `.zip` file containing the latest application code.
    * `lambda:UpdateFunctionConfiguration`: Allows changes to settings like memory, environment variables, or timeout.
    * `lambda:PublishVersion`: Allows the system to create a new, immutable version of the Lambda function after updating the code. This is crucial for safe deployments and potential rollbacks.
    * `lambda:Get*` / `lambda:List*`: Allows the system to read the current state of the Lambda function to verify changes.

* **API Gateway Management**:
    * `apigateway:*`: Grants full permission to manage the API Gateway integration. This is necessary to point the API route to the newly published version of the Lambda function, completing the deployment process. 

### 2. IAM Role Policy Attachment (`cc_app_role_policy_attach`) 

This resource takes the `CcAppRoleDeploymentPolicy` created above and **attaches it** to the application's main IAM Role (`cc_app_role`).

 
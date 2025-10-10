This Terraform code is for securely creating and managing secrets using the **AWS Systems Manager (SSM) Parameter Store**. 🤫

***

### 1. The Dynamic Parameter Creation

The `aws_ssm_parameter` resource is the core of this script. It's set up to be highly reusable using a `for_each` loop.

* **`for_each = var.params_keys`**: Instead of writing one resource block for each secret, this tells Terraform to loop through a list of keys (`var.params_keys`) and create a separate SSM parameter for each one.
* **`name = each.key`**: For each iteration of the loop, the name of the SSM parameter is set to the current key (e.g., `DB_PASSWORD`).
* **`type = "SecureString"`**: This is the most important setting. It instructs AWS to **encrypt** the parameter's value using the AWS Key Management Service (KMS). This ensures your secrets are stored securely at rest.
* **`value = var.cc_sensitive_params[each.key]`**: The actual secret value is looked up from an input variable map (`var.cc_sensitive_params`) using the current key.

***

### 2. The Secure Output

The `output "sensitive_params"` block is designed to export the details of the parameters that were just created, but without exposing the secret values in your terminal logs.

* **`value`**: It constructs a map of all the newly created SSM parameter objects.
* **`sensitive = true`**: This critical flag tells Terraform that the output contains sensitive data. As a result, when you run `terraform apply`, Terraform will hide the value of this output and simply display `<sensitive>` on the screen, preventing your secrets from being accidentally logged or displayed.

***

### The Workflow in Action

1.  You provide a map of secrets to the `cc_sensitive_params` variable, for example: `{ "DB_PASSWORD" = "MySuperSecretPassword123", "API_KEY" = "xyz-abc-789" }`.
2.  Terraform automatically derives the keys (`["DB_PASSWORD", "API_KEY"]`) for the `params_keys` variable.
3.  The `for_each` loop runs twice, creating two encrypted `SecureString` parameters in the AWS SSM Parameter Store.
4.  After applying, Terraform's output is marked as sensitive, keeping your secrets safe from exposure.
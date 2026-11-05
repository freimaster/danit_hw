terraform {
  required_version = ">= 1.10, < 2.0"
}

variable "password" {
  description = "Argo CD admin password supplied from the local .env file."
  type        = string
  sensitive   = true
  validation {
    condition     = can(regex("^[!-~]{12,72}$", var.password))
    error_message = "Use 12-72 printable ASCII characters without whitespace for ARGOCD_ADMIN_PASSWORD."
  }
}

# bcrypt uses a random salt. Keep the hash until the supplied password changes.
resource "terraform_data" "password" {
  input            = bcrypt(var.password)
  triggers_replace = var.password
  lifecycle {
    ignore_changes = [input]
  }
}

output "bcrypt_hash" {
  value     = terraform_data.password.output
  sensitive = true
}

variable "repo_url" {
  description = "Git repository watched by Argo CD."
  type        = string
  default     = "https://github.com/freimaster/test.git"
}

variable "git_token" {
  description = "Read access token for a private GitHub repository; empty for public repositories. Set via TF_VAR_git_token."
  type        = string
  sensitive   = true
  default     = ""
}

variable "argocd_admin_password" {
  description = "Argo CD admin password. Set via ARGOCD_ADMIN_PASSWORD in .env and the project script."
  type        = string
  sensitive   = true
}

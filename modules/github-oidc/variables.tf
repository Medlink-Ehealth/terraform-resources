# ─────────────────────────────────────────────────────────────────────────────
# modules/github-oidc/variables.tf
# ─────────────────────────────────────────────────────────────────────────────

variable "app_object_id" {
  description = "Object ID of the existing Entra application registration GitHub Actions authenticates as."
  type        = string
}

variable "github_org" {
  description = "GitHub organisation that owns the repositories."
  type        = string
  default     = "Medlink-Ehealth"
}

variable "repositories" {
  description = "Repository names (without the org prefix) to trust via GitHub OIDC."
  type        = list(string)
}

variable "branches" {
  description = "Branches whose workflows may request tokens (subject ref:refs/heads/<branch>)."
  type        = list(string)
  default     = ["main"]
}

variable "enable_pull_request" {
  description = "Whether to trust the pull_request subject for each repo."
  type        = bool
  default     = true
}

variable "github_environments" {
  description = "GitHub Environment names to trust (subject environment:<name>)."
  type        = list(string)
  default     = []
}

variable "credential_name_overrides" {
  description = "Optional map of subject => display name, used to adopt pre-existing credentials without renaming them."
  type        = map(string)
  default     = {}
}

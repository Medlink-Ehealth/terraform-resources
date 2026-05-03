# ─────────────────────────────────────────────────────────────────────────────
# environments/dev/variables.tf
# Declares all variables used in this environment.
# Actual values live in terraform.tfvars (gitignored — never commit that file).
# ─────────────────────────────────────────────────────────────────────────────

# ── Azure Account ─────────────────────────────────────────────────────────────
# These 4 values are what you change to switch between
# your personal subscription and the company subscription.

variable "subscription_id" {
  description = "Azure Subscription ID."
  type        = string
  sensitive   = true # Terraform will never print this in logs
}

variable "tenant_id" {
  description = "Azure Active Directory Tenant ID."
  type        = string
  sensitive   = true
}

variable "client_id" {
  description = "Service Principal App (Client) ID."
  type        = string
  sensitive   = true
}

variable "client_secret" {
  description = "Service Principal Client Secret. Never hardcode — always use tfvars."
  type        = string
  sensitive   = true
}

# ── Environment ───────────────────────────────────────────────────────────────

variable "environment" {
  description = "Deployment environment. Always 'dev' for this folder."
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region to deploy all resources into."
  type        = string
  default     = "australiaeast"
}

# ── Resource Group ────────────────────────────────────────────────────────────

variable "resource_group_name" {
  description = "Name of the resource group for all dev resources."
  type        = string
  default     = "medlink-dev-rg"
}

# ── Tagging ───────────────────────────────────────────────────────────────────

variable "owner" {
  description = "Your email — used for tagging and cost attribution."
  type        = string
}

variable "project" {
  description = "Project name for tagging."
  type        = string
  default     = "medlink"
}

variable "cost_center" {
  description = "Cost center for billing tags."
  type        = string
  default     = "medlink-engineering"
}

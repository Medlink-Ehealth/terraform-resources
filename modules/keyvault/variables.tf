# ─────────────────────────────────────────────────────────────────────────────
# modules/keyvault/variables.tf
# MED-19: Azure Key Vault (shared secrets store)
# Owner: Michael Olomide
# ─────────────────────────────────────────────────────────────────────────────

variable "resource_group_name" {
  description = "Name of the Azure Resource Group."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "key_vault_name" {
  description = "Name of the Key Vault."
  type        = string
  default     = "medlink-shared-kv"
}

variable "tenant_id" {
  description = "Azure AD Tenant ID — required for Key Vault configuration."
  type        = string
}

variable "workload_identity_principal_id" {
  description = "Object ID of the AKS Workload Identity — granted Secrets User role."
  type        = string
}

variable "devops_principal_id" {
  description = "Object ID of the DevOps service principal — granted Secrets Officer role."
  type        = string
}

variable "environment" {
  description = "Deployment environment label."
  type        = string
}

variable "project" {
  description = "Project name for tagging."
  type        = string
  default     = "medlink"
}

variable "owner" {
  description = "Owner email for tagging."
  type        = string
}

variable "cost_center" {
  description = "Cost center for billing tags."
  type        = string
  default     = "medlink-engineering"
}

variable "region" {
  description = "Azure region label for tagging."
  type        = string
  default     = ""
}

variable "business_unit" {
  description = "Business unit responsible for the resources."
  type        = string
  default     = "engineering"
}

variable "criticality" {
  description = "Resource criticality per CAF. Values: low, medium, high, mission-critical."
  type        = string
  default     = "low"
}

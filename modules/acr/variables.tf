# ─────────────────────────────────────────────────────────────────────────────
# modules/acr/variables.tf
# MED-19: Azure Container Registry
# ─────────────────────────────────────────────────────────────────────────────

variable "resource_group_name" {
  description = "Resource group where the ACR will be created."
  type        = string
}

variable "location" {
  description = "Azure region for the ACR (should match AKS region for low-latency pulls)."
  type        = string
}

variable "acr_name" {
  description = "Globally-unique ACR name (5-50 alphanumeric chars)."
  type        = string
}

variable "sku" {
  description = "ACR SKU. Allowed: Basic, Standard, Premium."
  type        = string
  default     = "Basic"
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.sku)
    error_message = "sku must be one of Basic, Standard, Premium."
  }
}

variable "admin_enabled" {
  description = "Whether to enable the admin user. Leave false — use AAD/AcrPull instead."
  type        = bool
  default     = false
}

variable "kubelet_identity_object_id" {
  description = "Object ID of the AKS kubelet managed identity — granted AcrPull on the ACR."
  type        = string
}

variable "environment" {
  description = "Deployment environment label (e.g. dev, prod)."
  type        = string
  default     = ""
}

variable "project" {
  description = "Project name for tagging."
  type        = string
  default     = "medlink"
}

variable "owner" {
  description = "Owner email for tagging."
  type        = string
  default     = ""
}

variable "cost_center" {
  description = "Cost center for billing tags."
  type        = string
  default     = "medlink-engineering"
}

variable "region" {
  description = "Azure region label for tagging (free-form)."
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

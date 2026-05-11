# ─────────────────────────────────────────────────────────────────────────────
# modules/acr/variables.tf
# MED-19: Azure Container Registry
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

variable "acr_name" {
  description = "Name of the Container Registry. Must be globally unique, alphanumeric only."
  type        = string
  default     = "medlinkdevacr"
}

variable "sku" {
  description = "ACR SKU. Basic is sufficient for dev."
  type        = string
  default     = "Basic"
}

variable "kubelet_identity_object_id" {
  description = "Object ID of the AKS kubelet managed identity — granted AcrPull role."
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

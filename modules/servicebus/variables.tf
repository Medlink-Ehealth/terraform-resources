# ─────────────────────────────────────────────────────────────────────────────
# modules/servicebus/variables.tf
# MED-19: Azure Service Bus
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

variable "servicebus_namespace_name" {
  description = "Name of the Service Bus namespace."
  type        = string
  default     = "medlink-servicebus"
}

variable "sku" {
  description = "Service Bus SKU. Standard supports topics and subscriptions."
  type        = string
  default     = "Standard"
}

variable "topics" {
  description = "List of Service Bus topics to create."
  type        = list(string)
  default     = ["appointments", "prescriptions", "notifications"]
}

variable "key_vault_id" {
  description = "Key Vault ID to store Service Bus connection string."
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

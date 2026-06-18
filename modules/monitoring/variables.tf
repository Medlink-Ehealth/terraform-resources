# ─────────────────────────────────────────────────────────────────────────────
# modules/monitoring/variables.tf
# MED-D-52: Azure Monitor, Log Analytics, Alert Rules
# Owner: Pelumi
# ─────────────────────────────────────────────────────────────────────────────

variable "resource_group_name" {
  description = "Name of the Azure Resource Group."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace."
  type        = string
  default     = "medlink-logs"
}

variable "aks_cluster_id" {
  description = "Resource ID of the AKS cluster — for diagnostic settings."
  type        = string
}

variable "retention_in_days" {
  description = "Number of days to retain logs in Log Analytics."
  type        = number
  default     = 30
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

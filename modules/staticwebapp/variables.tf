# ─────────────────────────────────────────────────────────────────────────────
# modules/staticwebapp/variables.tf
# MED-289: Azure Static Web Apps
# Owner: Pelumi + Michael
# ─────────────────────────────────────────────────────────────────────────────

variable "resource_group_name" {
  description = "Name of the Azure Resource Group."
  type        = string
}

variable "location" {
  description = "Azure region. Static Web Apps have limited region availability."
  type        = string
  default     = "eastasia"
}

variable "static_web_app_name" {
  description = "Name of the Static Web App."
  type        = string
  default     = "medlink-web"
}

variable "sku_tier" {
  description = "SKU tier. Free for dev, Standard for prod (custom domains + auth)."
  type        = string
  default     = "Free"
}

variable "sku_size" {
  description = "SKU size."
  type        = string
  default     = "Free"
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

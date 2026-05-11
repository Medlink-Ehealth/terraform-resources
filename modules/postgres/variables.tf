# ─────────────────────────────────────────────────────────────────────────────
# modules/postgres/variables.tf
# MED-19: PostgreSQL Flexible Server
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

variable "postgres_server_name" {
  description = "Name of the PostgreSQL Flexible Server."
  type        = string
  default     = "medlink-psql"
}

variable "postgres_version" {
  description = "PostgreSQL version."
  type        = string
  default     = "15"
}

variable "admin_username" {
  description = "Administrator username for the PostgreSQL server."
  type        = string
  default     = "medlinkadmin"
}

variable "admin_password" {
  description = "Administrator password. Passed via pipeline secret — never hardcoded."
  type        = string
  sensitive   = true
}

variable "sku_name" {
  description = "SKU for the PostgreSQL server. B1ms = Burstable 1 vCore (dev)."
  type        = string
  default     = "B_Standard_B1ms"
}

variable "storage_mb" {
  description = "Storage allocated to the PostgreSQL server in MB."
  type        = number
  default     = 32768
}

variable "subnet_postgres_id" {
  description = "Subnet ID for PostgreSQL private endpoint — from network module output."
  type        = string
}

variable "key_vault_id" {
  description = "Key Vault ID to store PostgreSQL connection string."
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

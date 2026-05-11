# ─────────────────────────────────────────────────────────────────────────────
# modules/storage/variables.tf
# All inputs the root module must pass in.
# ─────────────────────────────────────────────────────────────────────────────

# ── Resource placement ────────────────────────────────────────────────────────

variable "resource_group_name" {
  description = "Name of the Azure Resource Group to deploy storage into."
  type        = string
}

variable "location" {
  description = "Azure region. Must match the rest of the infrastructure."
  type        = string
}

# ── Storage Account ───────────────────────────────────────────────────────────

variable "storage_account_name" {
  description = "Name of the storage account. Must be globally unique, 3-24 chars, lowercase and numbers only."
  type        = string
  default     = "medlinkstoragedev"
}

variable "account_tier" {
  description = "Storage account performance tier. Standard is sufficient for blob storage."
  type        = string
  default     = "Standard"
}

variable "account_replication_type" {
  description = "Data replication strategy. LRS = Locally Redundant Storage (3 copies in one region). Use GRS for prod."
  type        = string
  default     = "LRS"
}

# ── Soft Delete ───────────────────────────────────────────────────────────────

variable "soft_delete_retention_days" {
  description = "Number of days deleted blobs are retained and recoverable. Applied to documents and pdfs containers."
  type        = number
  default     = 7
}

# ── Lifecycle Policy ──────────────────────────────────────────────────────────

variable "cool_tier_after_days" {
  description = "Number of days before blobs are moved to Cool storage tier. Cool is cheaper but slower to access."
  type        = number
  default     = 90
}

variable "archive_tier_after_days" {
  description = "Number of days before blobs are moved to Archive storage tier. Archive is cheapest but takes hours to retrieve."
  type        = number
  default     = 365
}

# ── Tagging ───────────────────────────────────────────────────────────────────

variable "environment" {
  description = "Deployment environment label. e.g. 'dev', 'staging', 'prod'"
  type        = string
}

variable "project" {
  description = "Project name for tagging."
  type        = string
  default     = "medlink"
}

variable "owner" {
  description = "Owner email for tagging and cost attribution."
  type        = string
}

variable "cost_center" {
  description = "Cost center for billing tags."
  type        = string
  default     = "medlink-engineering"
}

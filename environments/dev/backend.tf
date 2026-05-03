# ─────────────────────────────────────────────────────────────────────────────
# environments/dev/backend.tf
# Stores Terraform state in Azure Blob Storage so the whole team shares
# the same state and no one overwrites each other's changes.
#
# ⚠️  Run scripts/init-backend.sh FIRST to create the storage account.
#     Then replace the storage_account_name value below with the output.
# ─────────────────────────────────────────────────────────────────────────────

terraform {
  backend "azurerm" {
    resource_group_name  = "medlink-tfstate-rg"
    storage_account_name = "medlinktfstatedev" # ← replace with output from init-backend.sh
    container_name       = "medlink-tfstate"
    key                  = "dev/terraform.tfstate"
    use_azuread_auth     = true
  }
}

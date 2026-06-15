# ─────────────────────────────────────────────────────────────────────────────
# backend.tf
# Remote state backend — Azure Storage in Medlink-base-RG (westeurope).
# Authentication uses Azure AD (storage_use_azuread = true in provider.tf),
# so the signed-in user / service principal needs
# "Storage Blob Data Contributor" on the storage account.
# ─────────────────────────────────────────────────────────────────────────────

terraform {
  backend "azurerm" {
    resource_group_name  = "Medlink-base-RG"
    storage_account_name = "stmedlinktfstateormujd"
    container_name       = "tfstate"
    key                  = "dev/terraform.tfstate"
    use_azuread_auth     = true
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# modules/storage/outputs.tf
# Exports storage account details so other modules and pipelines
# can reference the containers without hardcoding names or IDs.
# ─────────────────────────────────────────────────────────────────────────────

output "storage_account_id" {
  description = "Resource ID of the storage account."
  value       = azurerm_storage_account.main.id
}

output "storage_account_name" {
  description = "Name of the storage account — used to configure the Terraform backend."
  value       = azurerm_storage_account.main.name
}

output "primary_blob_endpoint" {
  description = "Primary blob service endpoint URL — used by apps to upload/download files."
  value       = azurerm_storage_account.main.primary_blob_endpoint
}

output "documents_container_name" {
  description = "Name of the patient documents container."
  value       = azurerm_storage_container.documents.name
}

output "pdfs_container_name" {
  description = "Name of the PDFs container."
  value       = azurerm_storage_container.pdfs.name
}

output "tfstate_container_name" {
  description = "Name of the Terraform state container."
  value       = azurerm_storage_container.tfstate.name
}

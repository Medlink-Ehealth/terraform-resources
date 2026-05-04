# ─────────────────────────────────────────────────────────────────────────────
# provider.tf
# Pins Terraform version, declares the AzureRM provider and configures it.
# Credentials are never stored here — they are passed via environment variables:
#
# Locally:
#   export ARM_CLIENT_ID=$AZURE_CLIENT_ID
#   export ARM_CLIENT_SECRET=$AZURE_CLIENT_SECRET
#   export ARM_SUBSCRIPTION_ID=$AZURE_SUBSCRIPTION_ID
#   export ARM_TENANT_ID=$AZURE_TENANT_ID
#
# In GitHub Actions pipeline:
#   These are set automatically from GitHub Organisation Secrets.
# ─────────────────────────────────────────────────────────────────────────────

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.110.0"
    }
  }
}

provider "azurerm" {
  features {}
}

#!/bin/bash

set -euo pipefail

RESOURCE_GROUP="medlink-tfstate-rg"
LOCATION="eastus2"
CONTAINER_NAME="medlink-tfstate"
RANDOM_SUFFIX=$(LC_ALL=C tr -dc 'a-z0-9' < /dev/urandom | fold -w 6 | head -n 1)
STORAGE_ACCOUNT_NAME="medlinktfstate${RANDOM_SUFFIX}"

echo ""
echo "======================================================"
echo "  MedLink — Terraform Backend Initialisation Script"
echo "======================================================"
echo ""

echo "▶  Step 1/4 — Logging into Azure..."
az login --output none
echo "   ✅ Logged in successfully."
echo ""

echo "▶  Step 2/4 — Creating resource group: $RESOURCE_GROUP..."
az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --tags project=medlink managed_by=terraform purpose=tfstate \
  --output none
echo "   ✅ Resource group created."
echo ""

echo "▶  Step 3/4 — Creating storage account: $STORAGE_ACCOUNT_NAME..."
az storage account create \
  --name "$STORAGE_ACCOUNT_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false \
  --tags project=medlink managed_by=terraform purpose=tfstate \
  --output none
echo "   ✅ Storage account created."
echo ""

echo "▶  Step 4/4 — Creating blob container: $CONTAINER_NAME..."
az storage container create \
  --name "$CONTAINER_NAME" \
  --account-name "$STORAGE_ACCOUNT_NAME" \
  --auth-mode login \
  --output none
echo "   ✅ Container created."
echo ""

echo "======================================================"
echo "  ✅ Backend setup complete!"
echo "======================================================"
echo ""
echo "  Storage Account Name: $STORAGE_ACCOUNT_NAME"
echo "  Resource Group:       $RESOURCE_GROUP"
echo "  Container:            $CONTAINER_NAME"
echo ""
echo "  ⚠️  ACTION REQUIRED:"
echo "  Open environments/dev/backend.tf and replace:"
echo "    storage_account_name = \"medlinktfstate\""
echo "  with:"
echo "    storage_account_name = \"$STORAGE_ACCOUNT_NAME\""
echo ""
echo "  Then run:"
echo "    cd environments/dev"
echo "    terraform init"
echo ""
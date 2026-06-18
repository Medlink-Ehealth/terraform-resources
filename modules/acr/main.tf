# ─────────────────────────────────────────────────────────────────────────────
# modules/acr/main.tf
# MED-19: Create Azure Container Registry in the workload region and grant
# AKS pull access via the kubelet managed identity.
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_container_registry" "main" {
  name                = var.acr_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  admin_enabled       = var.admin_enabled

  tags = {
    env          = var.environment
    app          = var.project
    region       = var.region
    managed_by   = "terraform"
    costcenter   = var.cost_center
    opsteam      = var.owner
    businessunit = var.business_unit
    criticality  = var.criticality
  }
}

resource "azurerm_role_assignment" "aks_acrpull" {
  scope                            = azurerm_container_registry.main.id
  role_definition_name             = "AcrPull"
  principal_id                     = var.kubelet_identity_object_id
  skip_service_principal_aad_check = true
}

# ─────────────────────────────────────────────────────────────────────────────
# modules/network/main.tf
# MED-17: Provision Azure Networking — VNet, Subnets, NSGs
# Front Door excluded until AKS NGINX Ingress IP is known (MED-18).
# ─────────────────────────────────────────────────────────────────────────────

# ── Local values ──────────────────────────────────────────────────────────────
# Builds a shared tag map applied to every resource.
# Define once here instead of repeating on every resource block.

locals {
  common_tags = {
    environment = var.environment
    project     = var.project
    owner       = var.owner
    cost_center = var.cost_center
    managed_by  = "terraform"
    module      = "network"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# VIRTUAL NETWORK
# The parent network. Everything else (subnets, AKS, Postgres) lives inside it.
# address_space = the total IP range available across all subnets combined.
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_virtual_network" "main" {
  name                = "${var.vnet_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.vnet_address_space

  tags = local.common_tags
}

# ─────────────────────────────────────────────────────────────────────────────
# SUBNETS
# Subnets carve the VNet into isolated segments.
# Each segment is used for a different purpose so traffic can be controlled.
# ─────────────────────────────────────────────────────────────────────────────

# Subnet 1 — AKS nodes (10.0.1.0/24)
# This is where your Kubernetes pods and worker nodes run.
# service_endpoints allows pods to pull images from ACR privately.
resource "azurerm_subnet" "aks_nodes" {
  name                 = var.subnet_aks_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnet_aks_cidr]

  service_endpoints = ["Microsoft.ContainerRegistry"]
}

# Subnet 2 — PostgreSQL Private Endpoint (10.0.2.0/24)
# Private endpoints allow the database to be accessed inside the VNet only.
# No public internet can reach it at all.
# private_endpoint_network_policies_enabled = false is REQUIRED for private
# endpoints to work on this subnet — Azure enforces this.
resource "azurerm_subnet" "postgres_pe" {
  name                 = var.subnet_postgres_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnet_postgres_cidr]

  private_endpoint_network_policies = "Disabled"
}

# Subnet 3 — Gateway (10.0.3.0/24)
# Reserved for Azure Front Door health probes and future App Gateway.
# Empty for now — will be wired up when Front Door is added after MED-18.
resource "azurerm_subnet" "gateway" {
  name                 = var.subnet_gateway_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnet_gateway_cidr]
}

# ─────────────────────────────────────────────────────────────────────────────
# NETWORK SECURITY GROUPS (NSGs)
# NSGs are firewalls attached to subnets.
# Rules are evaluated lowest priority number first (100 before 4096).
# ─────────────────────────────────────────────────────────────────────────────

# ── NSG 1: AKS Nodes ──────────────────────────────────────────────────────────
# Allows internal pod-to-pod traffic and Azure load balancer probes.
# Blocks ALL public internet inbound — AKS API server is handled separately.

resource "azurerm_network_security_group" "aks_nodes" {
  name                = "nsg-aks-nodes-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name

  # INBOUND: Allow traffic from within the VNet (pod-to-pod, service-to-service)
  security_rule {
    name                       = "AllowVNetInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  # INBOUND: Allow Azure Load Balancer health probes.
  # Without this, AKS internal load balancers break silently.
  security_rule {
    name                       = "AllowAzureLoadBalancerInbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  # INBOUND: Block everything else from the public internet.
  # Priority 4096 = last rule evaluated = catch-all deny.
  security_rule {
    name                       = "DenyAllPublicInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  # OUTBOUND: Allow pods to pull images from Azure Container Registry (ACR).
  security_rule {
    name                       = "AllowACROutbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureContainerRegistry"
  }

  # OUTBOUND: Allow pods to reach the internet on HTTP/HTTPS.
  security_rule {
    name                       = "AllowInternetOutbound"
    priority                   = 200
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "Internet"
  }

  tags = local.common_tags
}

# ── NSG 2: PostgreSQL Private Endpoint ────────────────────────────────────────
# Only the AKS nodes subnet can reach the database on port 5432.
# Everything else — including the public internet — is denied.

resource "azurerm_network_security_group" "postgres_pe" {
  name                = "nsg-postgres-pe-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name

  # INBOUND: Only allow Postgres traffic from the AKS subnet.
  # source_address_prefix uses the actual AKS CIDR so it's explicit.
  security_rule {
    name                       = "AllowPostgresFromAKS"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5432"
    source_address_prefix      = var.subnet_aks_cidr
    destination_address_prefix = "*"
  }

  # INBOUND: Deny everything else — no exceptions.
  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = local.common_tags
}

# ── NSG 3: Gateway ────────────────────────────────────────────────────────────
# Pre-configured for when Azure Front Door is added after MED-18.
# Allows HTTPS from the internet and HTTP health probes from Front Door.

resource "azurerm_network_security_group" "gateway" {
  name                = "nsg-gateway-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name

  # INBOUND: Allow HTTPS from public internet (user traffic via Front Door)
  security_rule {
    name                       = "AllowHTTPSInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  # INBOUND: Allow HTTP health probes from Azure Front Door specifically.
  # AzureFrontDoor.Backend service tag covers all Front Door probe IPs.
  security_rule {
    name                       = "AllowHTTPInbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "AzureFrontDoor.Backend"
    destination_address_prefix = "*"
  }

  # INBOUND: Allow Azure Load Balancer probes
  security_rule {
    name                       = "AllowAzureLoadBalancerInbound"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  tags = local.common_tags
}

# ─────────────────────────────────────────────────────────────────────────────
# NSG ASSOCIATIONS
# This wires each NSG to its subnet.
# Without this step the NSG exists but its rules do absolutely nothing.
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_subnet_network_security_group_association" "aks_nodes" {
  subnet_id                 = azurerm_subnet.aks_nodes.id
  network_security_group_id = azurerm_network_security_group.aks_nodes.id
}

resource "azurerm_subnet_network_security_group_association" "postgres_pe" {
  subnet_id                 = azurerm_subnet.postgres_pe.id
  network_security_group_id = azurerm_network_security_group.postgres_pe.id
}

resource "azurerm_subnet_network_security_group_association" "gateway" {
  subnet_id                 = azurerm_subnet.gateway.id
  network_security_group_id = azurerm_network_security_group.gateway.id
}

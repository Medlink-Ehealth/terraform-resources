# MedLink Terraform Infrastructure

![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.7.0-7B42BC?logo=terraform)
![AzureRM](https://img.shields.io/badge/AzureRM-~3.110.0-0078D4?logo=microsoftazure)
![Status](https://img.shields.io/badge/Status-Active-28a745)
![Sprint](https://img.shields.io/badge/Sprint-1%20%26%202-orange)
![Engineer](https://img.shields.io/badge/Cloud%20Engineer-Pelumi-blue)

> Infrastructure as Code for the **MedLink Health Platform** — provisioning Azure networking, AKS, and Front Door using Terraform modules.

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Folder Structure](#folder-structure)
- [Prerequisites](#prerequisites)
- [Authentication](#authentication)
- [Switching Subscriptions](#switching-subscriptions)
- [Getting Started](#getting-started)
- [What Gets Deployed](#what-gets-deployed)
- [Network Architecture](#network-architecture)
- [Switching Environments](#switching-environments)
- [Module Progress](#module-progress)

---

## Overview

This repository manages all Azure infrastructure for MedLink using a modular Terraform approach. A single set of root configuration files calls reusable modules, and environment-specific values are passed via `.tfvars` files at runtime — keeping the codebase DRY across dev, staging, and production.

| Ticket  | Module              | Description                               |
| ------- | ------------------- | ----------------------------------------- |
| MED-17  | `modules/network`   | VNet, Subnets, NSGs                       |
| MED-107 | `modules/aks`       | AKS Cluster, Key Vault, Workload Identity |
| MED-105 | `modules/frontdoor` | Azure Front Door Standard, WAF Policy     |

---

## Architecture

```
Internet
    │
    ▼
Azure Front Door (Standard SKU)
    │  WAF Policy — Detection mode (dev) / Prevention (prod)
    │  HTTP → HTTPS redirect
    │
    ▼
NGINX Ingress Controller (AKS)
    │
    ├──▶ Application Pods (Spot Node Pool — Standard_D2s_v4)
    │
    └──▶ PostgreSQL Private Endpoint (postgres-pe subnet)
              No public IP — VNet only
```

---

## Folder Structure

```
terraform-resources/
├── environments/
│   ├── dev.tfvars          # Dev values — safe to commit, no secrets
│   └── prod.tfvars         # Prod values — safe to commit, no secrets
│
├── modules/
│   ├── network/            # MED-17: VNet, Subnets, NSGs
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   │
│   ├── aks/                # MED-107: AKS, Key Vault, Workload Identity
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   │
│   └── frontdoor/          # MED-105: Front Door Standard + WAF
│       ├── main.tf
│       ├── outputs.tf
│       └── variables.tf
│
├── main.tf                 # Root — resource group + module calls
├── outputs.tf              # Root outputs printed after apply
├── variables.tf            # Root variable declarations
├── provider.tf             # AzureRM provider + Terraform version pin
├── .gitignore
└── README.md
```

> **Key design decision:** No environment-specific folders. One root configuration, multiple `tfvars` files. To deploy to a different environment, change the `--var-file` flag — no code changes needed.

---

## Prerequisites

Ensure the following tools are installed before working with this repository:

| Tool      | Version   | Install                                                                   |
| --------- | --------- | ------------------------------------------------------------------------- |
| Terraform | >= 1.7.0  | [Download](https://developer.hashicorp.com/terraform/install)             |
| Azure CLI | >= 2.50.0 | [Download](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) |
| kubectl   | Latest    | [Download](https://kubernetes.io/docs/tasks/tools/)                       |
| Helm      | >= 3.x    | [Download](https://helm.sh/docs/intro/install/)                           |

---

## Authentication

> ⚠️ **Credentials are never stored in this repository.** They are passed via environment variables only.

### Local Development

Export the following environment variables before running any Terraform command:

```bash
export ARM_SUBSCRIPTION_ID="your-subscription-id"
export ARM_TENANT_ID="your-tenant-id"
export ARM_CLIENT_ID="your-client-id"
export ARM_CLIENT_SECRET="your-client-secret"
```

### GitHub Actions Pipeline

The pipeline reads credentials automatically from GitHub Organisation Secrets:

| Secret Name             | Description                |
| ----------------------- | -------------------------- |
| `AZURE_SUBSCRIPTION_ID` | Azure Subscription ID      |
| `AZURE_TENANT_ID`       | Azure AD Tenant ID         |
| `AZURE_CLIENT_ID`       | Service Principal App ID   |
| `AZURE_CLIENT_SECRET`   | Service Principal Password |

---

## Switching Subscriptions

> 💡 This repo is currently being tested on a **personal Azure subscription**. It will be switched to the company subscription once testing is complete. No code changes are needed — only the environment variables change.

### Personal Subscription (Testing)

```bash
export ARM_SUBSCRIPTION_ID="your-personal-subscription-id"
export ARM_TENANT_ID="your-personal-tenant-id"
export ARM_CLIENT_ID="your-personal-client-id"
export ARM_CLIENT_SECRET="your-personal-client-secret"
```

### Company Subscription (Production use)

```bash
export ARM_SUBSCRIPTION_ID="company-subscription-id"
export ARM_TENANT_ID="company-tenant-id"
export ARM_CLIENT_ID="company-client-id"
export ARM_CLIENT_SECRET="company-client-secret"
```

After swapping credentials, re-initialise Terraform to reconnect the backend:

```bash
terraform init -reconfigure
terraform plan -var-file=environments/dev.tfvars -out=plan.tfplan
```

> ⚠️ Never commit credentials to this repository. Always use environment variables or GitHub Organisation Secrets.

---

## Getting Started

### Step 1 — Clone the repository

```bash
git clone https://github.com/Medlink-Ehealth/terraform-resources.git
cd terraform-resources
```

### Step 2 — Check out your branch

```bash
git checkout -b feature/YOUR-TICKET-your-name
```

### Step 3 — Export credentials

```bash
export ARM_SUBSCRIPTION_ID="your-subscription-id"
export ARM_TENANT_ID="your-tenant-id"
export ARM_CLIENT_ID="your-client-id"
export ARM_CLIENT_SECRET="your-client-secret"
```

### Step 4 — Initialise Terraform

```bash
terraform init
```

### Step 5 — Plan and apply

```bash
# Preview changes
terraform plan -var-file=environments/dev.tfvars -out=plan.tfplan

# Review the plan output, then deploy
terraform apply plan.tfplan
```

### Step 6 — Destroy when done testing

```bash
terraform destroy -var-file=environments/dev.tfvars
```

---

## What Gets Deployed

### Network Module — MED-17

| Resource             | Name                  | Details                               |
| -------------------- | --------------------- | ------------------------------------- |
| Resource Group       | `medlink-dev-rg`      | Australia East                        |
| Virtual Network      | `medlink-vnet-dev`    | `10.0.0.0/16`                         |
| Subnet — AKS Nodes   | `aks-nodes`           | `10.0.1.0/24`                         |
| Subnet — Postgres PE | `postgres-pe`         | `10.0.2.0/24`                         |
| Subnet — Gateway     | `gateway`             | `10.0.3.0/24`                         |
| NSG — AKS            | `nsg-aks-nodes-dev`   | Internal VNet only, no public inbound |
| NSG — Postgres       | `nsg-postgres-pe-dev` | Port 5432 from AKS subnet only        |
| NSG — Gateway        | `nsg-gateway-dev`     | HTTPS/HTTP inbound for Front Door     |

### AKS Module — MED-107

| Resource            | Name              | Details                                 |
| ------------------- | ----------------- | --------------------------------------- |
| AKS Cluster         | `medlink-dev-aks` | Kubernetes 1.35.3, Australia East       |
| System Node Pool    | `system`          | 1x Standard_D2s_v4, on-demand           |
| Spot User Node Pool | `spot`            | Standard_D2s_v4, min 1 / max 3          |
| Cluster Autoscaler  | enabled           | Scales spot pool between min/max        |
| Key Vault           | `medlink-kv-dev`  | Stores cluster secrets                  |
| Workload Identity   | enabled           | Keyless Azure resource access from pods |
| OIDC Issuer         | enabled           | Required for Workload Identity          |

### Front Door Module — MED-105

| Resource           | Name                          | Details                                 |
| ------------------ | ----------------------------- | --------------------------------------- |
| Front Door Profile | `medlink-frontdoor-dev`       | Standard SKU                            |
| Endpoint           | `medlink-dev`                 | `*.azurefd.net` public hostname         |
| Origin Group       | `medlink-origin-group-dev`    | Health probe every 100s on `/healthz`   |
| Origin             | `nginx-ingress-dev`           | NGINX Ingress Controller external IP    |
| Route              | `medlink-route-dev`           | All paths, HTTP → HTTPS redirect        |
| WAF Policy         | `medlinkwafpolicy`            | Detection mode (dev), Prevention (prod) |
| Security Policy    | `medlink-security-policy-dev` | WAF enforced on all traffic             |

---

## Network Architecture

The networking layer is built in three isolated tiers inside a single Virtual Network (VNet). Every resource in the MedLink platform lives inside this VNet — nothing is exposed to the public internet unless explicitly opened.

---

### The VNet — `medlink-vnet-dev` (`10.0.0.0/16`)

Think of the VNet as your private data centre inside Azure. Nothing outside it can talk to anything inside it unless you explicitly open a door. The `/16` address space gives you 65,536 IP addresses to distribute across all subnets. Everything in this project — AKS, PostgreSQL, Redis, Front Door — lives inside this one VNet.

---

### The Three Subnets

Subnets carve the VNet into isolated segments. Each segment has its own IP range and its own firewall (NSG). Isolating workloads this way means a compromised pod cannot automatically reach the database.

**`aks-nodes` — `10.0.1.0/24`**

This is where your Kubernetes worker nodes and pods run. The `/24` gives 256 IP addresses — enough headroom for pods to scale up. It has a service endpoint to Azure Container Registry so pods can pull Docker images privately without going over the public internet.

**`postgres-pe` — `10.0.2.0/24`**

This is where the PostgreSQL private endpoint lives. A private endpoint gives your database a private IP address inside the VNet instead of a public one. The database is completely invisible to the internet — it can only be reached from inside the VNet. The `private_endpoint_network_policies = "Disabled"` setting on this subnet is what makes private endpoints work.

**`gateway` — `10.0.3.0/24`**

Reserved for Azure Front Door. Front Door is the public entry point for the application — it handles CDN, SSL certificates, and the WAF (Web Application Firewall). Health probes from Front Door arrive on this subnet before being forwarded to the NGINX Ingress Controller.

---

### The NSGs — Firewall Rules Per Subnet

Each subnet has its own Network Security Group (NSG). Rules are evaluated from the lowest priority number first (100 = first, 4096 = last). If no rule matches, Azure denies the traffic by default.

**NSG on `aks-nodes`:**

- Pods can communicate with each other freely inside the VNet
- Azure Load Balancer can send health probes in (required for AKS to function)
- The public internet cannot send any inbound traffic — blocked at priority 4096
- Pods can reach Azure Container Registry on port 443 to pull images
- Pods can reach the internet on ports 80 and 443 for external API calls

**NSG on `postgres-pe`:**

- Only the AKS subnet (`10.0.1.0/24`) can connect, and only on port 5432 (PostgreSQL)
- Everything else is denied — no exceptions, no internet, no other subnets
- Even if someone had the database hostname, they could not connect from outside the VNet

**NSG on `gateway`:**

- HTTPS port 443 is open from the internet — this is user traffic arriving via Front Door
- HTTP port 80 is open only from Front Door's own IP range (`AzureFrontDoor.Backend`) — for health probes
- Azure Load Balancer probes are allowed in
- All other inbound traffic is denied

---

### NSG Associations — The Step That Activates Everything

Creating an NSG in Azure does nothing on its own. The three `azurerm_subnet_network_security_group_association` resources at the bottom of `modules/network/main.tf` are what attach each NSG to its subnet. Without these, all the firewall rules exist in Azure but are not enforced anywhere.

---

### How Modules Share Network Information

After the network deploys, `modules/network/outputs.tf` exports the subnet IDs and VNet name. The AKS module references `module.network.subnet_aks_id` to know exactly which subnet to deploy the cluster into. This avoids hardcoding any Azure resource IDs across modules.

---

### Traffic Flow Summary

| Traffic                         | Allowed? | Rule                                 |
| ------------------------------- | -------- | ------------------------------------ |
| Internet → AKS pods             | ❌ No    | DenyAllPublicInbound (priority 4096) |
| AKS pods → each other           | ✅ Yes   | AllowVNetInbound (priority 100)      |
| AKS pods → PostgreSQL port 5432 | ✅ Yes   | AllowPostgresFromAKS (priority 100)  |
| Internet → PostgreSQL           | ❌ No    | DenyAllInbound (priority 4096)       |
| AKS pods → ACR (image pull)     | ✅ Yes   | AllowACROutbound (priority 100)      |
| Internet → Gateway port 443     | ✅ Yes   | AllowHTTPSInbound (priority 100)     |
| Front Door → Gateway port 80    | ✅ Yes   | AllowHTTPInbound (priority 110)      |

---

## Switching Environments

No code changes are needed to switch environments. Simply pass a different `tfvars` file:

```bash
# Deploy to dev
terraform plan -var-file=environments/dev.tfvars -out=plan.tfplan
terraform apply plan.tfplan

# Deploy to prod
terraform plan -var-file=environments/prod.tfvars -out=plan.tfplan
terraform apply plan.tfplan
```

The `prod.tfvars` file uses larger VM sizes, higher node counts, and WAF in `Prevention` mode.

---

## Module Progress

| Ticket   | Module               | Owner   | Status      |
| -------- | -------------------- | ------- | ----------- |
| MED-17   | `modules/network`    | Pelumi  | ✅ Complete |
| MED-107  | `modules/aks`        | Pelumi  | ✅ Complete |
| MED-105  | `modules/frontdoor`  | Pelumi  | ✅ Complete |
| MED-118  | `modules/storage`    | Pelumi  | 🔜 Next     |
| MED-19   | `modules/postgres`   | Michael | 🔜 Upcoming |
| MED-19   | `modules/redis`      | Michael | 🔜 Upcoming |
| MED-19   | `modules/keyvault`   | Michael | 🔜 Upcoming |
| MED-D-52 | `modules/monitoring` | Pelumi  | 🔜 Sprint 5 |

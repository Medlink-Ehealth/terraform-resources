# MedLink — Terraform Infrastructure

> **MED-17** | Cloud Engineer: Pelumi | Sprint 1

Azure infrastructure for the MedLink Health Platform, managed via Terraform.
This module covers: VNet, Subnets, and NSGs.

---

## Quick Start (First Time Setup)

## Switching Between Subscriptions ← already there

## What Gets Deployed (MED-17) ← already there

## Network Architecture ← ADD HERE ✅

## Folder Structure ← already there

## Pushing to GitHub ← already there

## Next Modules ← already there

### Prerequisites

Make sure these are installed on your machine:

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.7.0
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) >= 2.50.0

### Step 1 — Create a Service Principal

Terraform needs its own Azure identity to authenticate. Run this once:

```bash
# Login with your personal account
az login

# Create a service principal scoped to your subscription
az ad sp create-for-rbac \
  --name "medlink-terraform-sp" \
  --role Contributor \
  --scopes /subscriptions/<YOUR_SUBSCRIPTION_ID>
```

Copy the output — you'll need `appId`, `password`, and `tenant` for the next step.

---

### Step 2 — Set Up Remote State Backend

Run this script once. It creates the Azure Storage Account for Terraform state.

```bash
chmod +x scripts/init-backend.sh
./scripts/init-backend.sh
```

After it runs, copy the **storage account name** from the output and update:

```
environments/dev/backend.tf  →  storage_account_name = "<name from script>"
```

---

### Step 3 — Configure Your Variables

```bash
cd environments/dev
cp terraform.tfvars.example terraform.tfvars
```

Open `terraform.tfvars` and fill in your values:

```hcl
subscription_id = "your-subscription-id"
tenant_id       = "your-tenant-id"
client_id       = "service-principal-app-id"
client_secret   = "service-principal-password"
owner           = "your-email@example.com"
```

> ⚠️ `terraform.tfvars` is in `.gitignore` — it will **never** be committed to GitHub.

---

### Step 4 — Initialise and Deploy

```bash
# From the repo root:
cd environments/dev
terraform init       # Downloads providers; connects to remote state

# Review what will be created (always do this before apply):
./scripts/plan.sh dev

# Deploy to Azure:
./scripts/apply.sh dev
```

---

## Switching Between Personal and Company Subscriptions

Update only your `terraform.tfvars`:

```hcl
# Personal subscription
subscription_id = "your-personal-sub-id"
tenant_id       = "your-personal-tenant-id"

# Company subscription (swap these values when ready)
# subscription_id = "company-sub-id"
# tenant_id       = "company-tenant-id"
```

Then re-run `terraform init` (to reinitialise the backend) and `plan.sh`.

---

## What Gets Deployed (MED-17)

| Resource             | Name                  | Details                                 |
| -------------------- | --------------------- | --------------------------------------- |
| Resource Group       | `medlink-dev-rg`      | East US 2                               |
| Virtual Network      | `medlink-vnet-dev`    | `10.0.0.0/16`                           |
| Subnet — AKS Nodes   | `aks-nodes`           | `10.0.1.0/24`                           |
| Subnet — Postgres PE | `postgres-pe`         | `10.0.2.0/24`                           |
| Subnet — Gateway     | `gateway`             | `10.0.3.0/24`                           |
| NSG — AKS            | `nsg-aks-nodes-dev`   | Internal VNet only; no public inbound   |
| NSG — Postgres       | `nsg-postgres-pe-dev` | Port 5432 from AKS subnet only          |
| NSG — Gateway        | `nsg-gateway-dev`     | HTTPS/HTTP inbound ready for Front Door |

---

## Network Architecture — How It All Fits Together

The networking layer is built in three tiers inside a single Virtual Network (VNet).
Every resource in the MedLink platform lives inside this VNet — nothing is exposed
to the public internet unless explicitly opened.

---

### The VNet — `medlink-vnet-dev` (`10.0.0.0/16`)

Think of the VNet as your private data centre inside Azure. Nothing outside it can
talk to anything inside it unless you explicitly open a door. The `/16` address space
gives you 65,536 IP addresses to distribute across all subnets. Everything in this
project — AKS, PostgreSQL, Redis, Front Door — lives inside this one VNet.

---

### The Three Subnets

Subnets carve the VNet into isolated segments. Each segment has its own IP range
and its own firewall (NSG). Isolating workloads this way means a compromised pod
cannot automatically reach the database.

**`aks-nodes` — `10.0.1.0/24`**
This is where your Kubernetes worker nodes and pods run. The `/24` gives 256 IP
addresses — enough headroom for pods to scale up. It has a service endpoint to
Azure Container Registry so pods can pull Docker images privately without going
over the public internet.

**`postgres-pe` — `10.0.2.0/24`**
This is where the PostgreSQL private endpoint lives. A private endpoint gives your
database a private IP address inside the VNet instead of a public one. The database
is completely invisible to the internet — it can only be reached from inside the VNet.
The `private_endpoint_network_policies = "Disabled"` setting on this subnet is what
makes private endpoints work.

**`gateway` — `10.0.3.0/24`**
Reserved for Azure Front Door. Front Door is the public entry point for the
application — it handles CDN, SSL certificates, and the WAF (Web Application Firewall).
It is not deployed yet because it needs the AKS NGINX Ingress IP, which comes from
MED-18 (the AKS module).

---

### The NSGs — Firewall Rules Per Subnet

Each subnet has its own Network Security Group (NSG). Rules are evaluated from the
lowest priority number first (100 = first, 4096 = last). If no rule matches,
Azure denies the traffic by default.

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

### NSG Associations — the Step That Activates Everything

Creating an NSG in Azure does nothing on its own. The three
`azurerm_subnet_network_security_group_association` resources at the bottom of
`modules/network/main.tf` are what attach each NSG to its subnet. Without these,
all the firewall rules exist in Azure but are not enforced anywhere.

---

### How Modules Share Network Information

After this deploys, `modules/network/outputs.tf` exports the subnet IDs and VNet
name. When MED-18 (AKS) is built, it references `module.network.subnet_aks_id` to
know exactly which subnet to deploy the cluster into. This avoids hardcoding any
Azure resource IDs across modules.

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

## Folder Structure

```
medlink-terraform/
├── environments/
│   └── dev/
│       ├── backend.tf           # Remote state config
│       ├── main.tf              # Provider + module calls
│       ├── variables.tf         # Variable declarations
│       ├── outputs.tf           # Values printed after apply
│       ├── terraform.tfvars     # ← YOUR SECRETS (gitignored)
│       └── terraform.tfvars.example
├── modules/
│   └── network/
│       ├── main.tf              # VNet, Subnets, NSGs
│       ├── variables.tf
│       ├── outputs.tf
│       └── versions.tf
├── scripts/
│   ├── init-backend.sh          # Run once to create remote state storage
│   ├── plan.sh                  # terraform fmt + validate + plan
│   └── apply.sh                 # Applies the saved plan
├── .gitignore
└── README.md
```

---

## Pushing to GitHub

```bash
git init
git remote add origin https://github.com/Medlink-Ehealth/terraform-resources.git
git add .
git commit -m "feat(MED-17): scaffold network module — VNet, subnets, NSGs"
git push -u origin main
```

> ⚠️ Always run `git status` before committing to confirm `terraform.tfvars` is NOT listed.

---

## Next Modules (Coming Soon)

- `modules/aks` — MED-18: AKS Cluster (Pelumi)
- `modules/storage` — MED-20: Blob Storage (Pelumi)
- `modules/postgres` — MED-19: PostgreSQL + Redis (Michael)

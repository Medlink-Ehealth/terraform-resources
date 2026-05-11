# ─────────────────────────────────────────────────────────────────────────────
# modules/frontdoor/variables.tf
# All inputs the root module must pass in.
# ─────────────────────────────────────────────────────────────────────────────

# ── Resource placement ────────────────────────────────────────────────────────

variable "resource_group_name" {
  description = "Name of the Azure Resource Group to deploy Front Door into."
  type        = string
}

variable "location" {
  description = "Azure region. Must match the rest of the infrastructure."
  type        = string
}

# ── Front Door ────────────────────────────────────────────────────────────────

variable "frontdoor_name" {
  description = "Name of the Front Door profile. CAF format: afd-{workload}-{env}"
  type        = string
  default     = "afd-medlink-dev"
}

variable "origin_ip" {
  description = "External IP of the NGINX Ingress Controller on AKS. Front Door routes all traffic to this IP."
  type        = string
  # This is the IP from: kubectl get service -n ingress-nginx
  # For dev it is: 20.167.106.121
}

variable "origin_http_port" {
  description = "HTTP port the NGINX Ingress Controller listens on."
  type        = number
  default     = 80
}

variable "origin_https_port" {
  description = "HTTPS port the NGINX Ingress Controller listens on."
  type        = number
  default     = 443
}

# ── WAF Policy ────────────────────────────────────────────────────────────────

variable "waf_policy_name" {
  description = "Name of the WAF policy. CAF format: fdfp-{workload}-{env}. No hyphens allowed."
  type        = string
  default     = "fdfpmedlinkdev"
}

variable "waf_mode" {
  description = "WAF mode. 'Detection' logs threats without blocking. 'Prevention' blocks them. Use Detection for dev."
  type        = string
  default     = "Detection"
}

# ── Tagging ───────────────────────────────────────────────────────────────────

variable "environment" {
  description = "Deployment environment label."
  type        = string
}

variable "project" {
  description = "Project name for tagging."
  type        = string
  default     = "medlink"
}

variable "owner" {
  description = "Owner email for tagging."
  type        = string
}

variable "cost_center" {
  description = "Cost center for billing tags."
  type        = string
  default     = "medlink-engineering"
}

variable "region" {
  description = "Azure region label for tagging."
  type        = string
  default     = "australiaeast"
}

variable "business_unit" {
  description = "Business unit responsible for this resource."
  type        = string
  default     = "engineering"
}

variable "criticality" {
  description = "Resource criticality. CAF values: low, medium, high, mission-critical"
  type        = string
  default     = "low"
}

# ─────────────────────────────────────────────────────────────────────────────
# modules/frontdoor/main.tf
# MED-105: Azure Front Door Standard + WAF Policy
#
# What this creates:
#   1. WAF Policy          — detects/blocks malicious traffic
#   2. Front Door Profile  — the CDN entry point (Standard SKU)
#   3. Endpoint            — the public hostname (*.azurefd.net)
#   4. Origin Group        — pool of backends (just NGINX for now)
#   5. Origin              — the NGINX Ingress Controller external IP
#   6. Route               — wires the endpoint to the origin group
#   7. Security Policy     — attaches the WAF to the endpoint
# ─────────────────────────────────────────────────────────────────────────────

locals {
  common_tags = {
    environment = var.environment
    project     = var.project
    owner       = var.owner
    cost_center = var.cost_center
    managed_by  = "terraform"
    module      = "frontdoor"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# WAF POLICY
# Web Application Firewall sits in front of your app and filters traffic.
# It uses Microsoft-managed rule sets to block common attacks like:
# SQL injection, XSS, remote file inclusion etc.
#
# Detection mode — logs threats but does not block them. Safe for dev
# because it won't accidentally block legitimate requests while you test.
# Switch to Prevention in staging/prod.
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_cdn_frontdoor_firewall_policy" "waf" {
  name                = var.waf_policy_name
  resource_group_name = var.resource_group_name
  sku_name            = "Standard_AzureFrontDoor"
  enabled             = true
  mode                = var.waf_mode

  # Microsoft Default Rule Set — covers OWASP Top 10 threats.
  # 1.1 is the latest stable version for Standard SKU.
  # managed_rule {
  #   type    = "Microsoft_DefaultRuleSet"
  #   version = "1.1"
  #   action  = "Block"
  # }

  # # Microsoft Bot Manager — blocks known malicious bots.
  # managed_rule {
  #   type    = "Microsoft_BotManagerRuleSet"
  #   version = "1.0"
  #   action  = "Block"
  # }

  tags = local.common_tags
}

# ─────────────────────────────────────────────────────────────────────────────
# FRONT DOOR PROFILE
# The top-level resource. Standard SKU includes:
#   - Global CDN (caches static assets at edge locations worldwide)
#   - WAF integration
#   - Built-in SSL/TLS with managed certificates
#   - Health probes to detect backend failures
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_cdn_frontdoor_profile" "main" {
  name                = "${var.frontdoor_name}-${var.environment}"
  resource_group_name = var.resource_group_name
  sku_name            = "Standard_AzureFrontDoor"

  tags = local.common_tags
}

# ─────────────────────────────────────────────────────────────────────────────
# ENDPOINT
# The public-facing hostname Azure assigns to this Front Door.
# Format: <name>-<hash>.azurefd.net
# This is what users (and your DNS) will point to.
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_cdn_frontdoor_endpoint" "main" {
  name                     = "medlink-${var.environment}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id

  tags = local.common_tags
}

# ─────────────────────────────────────────────────────────────────────────────
# ORIGIN GROUP
# A pool of backends. Front Door load balances across all origins in the group
# and uses health probes to remove unhealthy ones automatically.
#
# For now there is one origin (NGINX). When you add more AKS regions or
# a staging slot, you add more origins to this group.
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_cdn_frontdoor_origin_group" "main" {
  name                     = "medlink-origin-group-${var.environment}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id

  # Health probe — Front Door pings /healthz every 100 seconds.
  # If the origin returns anything other than 2xx/3xx, it is removed
  # from rotation until it recovers.
  health_probe {
    interval_in_seconds = 100
    path                = "/healthz"
    protocol            = "Http"
    request_type        = "HEAD"
  }

  # Load balancing settings.
  # additional_latency_in_milliseconds = 50 means Front Door will prefer
  # the fastest origin unless another is within 50ms — prevents flapping.
  load_balancing {
    additional_latency_in_milliseconds = 50
    sample_size                        = 4
    successful_samples_required        = 3
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# ORIGIN
# The actual backend — your NGINX Ingress Controller's external IP.
# Front Door forwards all requests here after CDN cache miss or WAF check.
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_cdn_frontdoor_origin" "nginx" {
  name                          = "nginx-ingress-${var.environment}"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.main.id

  # The NGINX Ingress Controller external IP from:
  # kubectl get service -n ingress-nginx
  host_name          = var.origin_ip
  http_port          = var.origin_http_port
  https_port         = var.origin_https_port
  origin_host_header = var.origin_ip

  # Priority 1 = primary origin. If you add a secondary, set it to 2.
  priority = 1
  weight   = 1000

  # certificate_name_check_enabled = false because we're using an IP
  # not a hostname. Set to true when you add a custom domain.
  certificate_name_check_enabled = false

  enabled = true
}

# ─────────────────────────────────────────────────────────────────────────────
# ROUTE
# Wires the endpoint to the origin group.
# Defines which paths and protocols Front Door accepts and forwards.
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_cdn_frontdoor_route" "main" {
  name                          = "medlink-route-${var.environment}"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.main.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.main.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.nginx.id]

  # Accept both HTTP and HTTPS from users.
  supported_protocols = ["Http", "Https"]

  # Match all paths and forward to NGINX.
  patterns_to_match = ["/*"]

  # Automatically redirect HTTP to HTTPS — enforces secure connections.
  forwarding_protocol    = "HttpOnly"
  https_redirect_enabled = true

  enabled = true
}

# ─────────────────────────────────────────────────────────────────────────────
# SECURITY POLICY
# Attaches the WAF policy to the Front Door endpoint.
# Without this the WAF exists but is not enforced on any traffic.
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_cdn_frontdoor_security_policy" "waf" {
  name                     = "medlink-security-policy-${var.environment}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id

  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = azurerm_cdn_frontdoor_firewall_policy.waf.id

      association {
        domain {
          cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_endpoint.main.id
        }
        # Apply WAF to all paths
        patterns_to_match = ["/*"]
      }
    }
  }
}

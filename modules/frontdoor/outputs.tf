# ─────────────────────────────────────────────────────────────────────────────
# modules/frontdoor/outputs.tf
# Exports the Front Door hostname so you can test it in a browser
# and reference it in DNS records when you add a custom domain.
# ─────────────────────────────────────────────────────────────────────────────

output "frontdoor_endpoint_hostname" {
  description = "Public hostname of the Front Door endpoint. Use this to test in a browser."
  value       = azurerm_cdn_frontdoor_endpoint.main.host_name
}

output "frontdoor_profile_id" {
  description = "Resource ID of the Front Door profile."
  value       = azurerm_cdn_frontdoor_profile.main.id
}

output "waf_policy_id" {
  description = "Resource ID of the WAF policy."
  value       = azurerm_cdn_frontdoor_firewall_policy.waf.id
}

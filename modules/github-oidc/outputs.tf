# ─────────────────────────────────────────────────────────────────────────────
# modules/github-oidc/outputs.tf
# ─────────────────────────────────────────────────────────────────────────────

output "federated_credential_subjects" {
  description = "Map of credential key => trusted GitHub OIDC subject."
  value       = { for k, c in azuread_application_federated_identity_credential.github : k => c.subject }
}

output "federated_credential_count" {
  description = "Number of federated identity credentials managed by this module."
  value       = length(azuread_application_federated_identity_credential.github)
}

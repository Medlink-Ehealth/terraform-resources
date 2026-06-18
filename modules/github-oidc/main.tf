# ─────────────────────────────────────────────────────────────────────────────
# modules/github-oidc/main.tf
# MED-100: GitHub Actions OIDC federated identity credentials
# Owner: Michael Olomide
#
# Adds federated identity credentials to an existing Entra application
# registration so GitHub Actions workflows can authenticate to Azure via OIDC
# (no long-lived secrets). One credential is created per (repo × subject):
#   - branch:       repo:<org>/<repo>:ref:refs/heads/<branch>
#   - pull_request: repo:<org>/<repo>:pull_request
#   - environment:  repo:<org>/<repo>:environment:<env>
#
# The application itself is NOT managed here — only its federated credentials.
# ─────────────────────────────────────────────────────────────────────────────

locals {
  # ── Branch subjects (repo × branch) ─────────────────────────────────────────
  branch_credentials = [
    for pair in setproduct(var.repositories, var.branches) : {
      key     = "${pair[0]}-branch-${pair[1]}"
      repo    = pair[0]
      subject = "repo:${var.github_org}/${pair[0]}:ref:refs/heads/${pair[1]}"
    }
  ]

  # ── Pull request subjects (one per repo) ────────────────────────────────────
  pull_request_credentials = var.enable_pull_request ? [
    for repo in var.repositories : {
      key     = "${repo}-pull-request"
      repo    = repo
      subject = "repo:${var.github_org}/${repo}:pull_request"
    }
  ] : []

  # ── Environment subjects (repo × environment) ───────────────────────────────
  environment_credentials = [
    for pair in setproduct(var.repositories, var.github_environments) : {
      key     = "${pair[0]}-env-${pair[1]}"
      repo    = pair[0]
      subject = "repo:${var.github_org}/${pair[0]}:environment:${pair[1]}"
    }
  ]

  # Flatten into a single keyed map for for_each.
  credentials = {
    for c in concat(
      local.branch_credentials,
      local.pull_request_credentials,
      local.environment_credentials,
    ) : c.key => c
  }
}

# ── Federated identity credentials ────────────────────────────────────────────
# audiences/issuer are fixed for GitHub Actions OIDC. The (issuer, subject) pair
# must be unique per application. credential_name_overrides lets pre-existing
# credentials keep their original display name so they adopt cleanly on import.
resource "azuread_application_federated_identity_credential" "github" {
  for_each = local.credentials

  application_id = "/applications/${var.app_object_id}"
  display_name   = lookup(var.credential_name_overrides, each.value.subject, each.key)
  description    = "GitHub OIDC — ${each.value.repo}"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = each.value.subject
}

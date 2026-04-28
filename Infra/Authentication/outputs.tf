data "aws_region" "current" {}

# If you use AWS-hosted cognito domain prefix:
# resource "aws_cognito_user_pool_domain" "web" { domain = "my-prefix" ... }

locals {
  # Cognito Hosted UI base URL (AWS-hosted domain prefix)
  cognito_hosted_ui_base_url = "https://${aws_cognito_user_pool_domain.web.domain}.auth.${data.aws_region.current.name}.amazoncognito.com"

  # This is the exact Redirect URI you must put into Google OAuth Client
  google_authorized_redirect_uri = "${local.cognito_hosted_ui_base_url}/oauth2/idpresponse"
}

output "cognito_hosted_ui_base_url" {
  description = "Base URL for Cognito hosted UI and OAuth endpoints."
  value       = local.cognito_hosted_ui_base_url
}

output "google_authorized_redirect_uri" {
  description = "Put this value into Google Cloud OAuth Client -> Authorized redirect URIs."
  value       = local.google_authorized_redirect_uri
}

# Optional but super helpful for frontend wiring:

output "cognito_authorize_endpoint" {
  description = "OAuth2 authorize endpoint (browser redirect)."
  value       = "${local.cognito_hosted_ui_base_url}/oauth2/authorize"
}

output "cognito_token_endpoint" {
  description = "OAuth2 token endpoint (exchange code for tokens)."
  value       = "${local.cognito_hosted_ui_base_url}/oauth2/token"
}

output "cognito_logout_endpoint" {
  description = "Logout endpoint for hosted UI."
  value       = "${local.cognito_hosted_ui_base_url}/logout"
}

# Also useful to output these:
output "cognito_user_pool_id" {
  value = aws_cognito_user_pool.web.id
}

output "cognito_user_pool_client_id" {
  value = aws_cognito_user_pool_client.web.id
}
``
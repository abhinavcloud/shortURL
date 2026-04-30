output "cloudfront_domain_name" {
  value       = module.Cloudfront.cloudfront_domain_name
  description = "CloudFront domain name"
}

output "distribution_id" {
  value       = module.Cloudfront.distribution_id
  description = "CloudFront distribution id (use in CI for invalidations)"
}

output "cognito_domain" {
  value = module.Authentication.cognito_domain
}

output "cognito_client_id" {
  value = module.Authentication.cognito_client_id
}

output "redirect_uri" {
  value = module.Authentication.redirect_uri
}

output "google_authorized_redirect_uri" {
  value = module.Authentication.google_authorized_redirect_uri
}

output "base_url" {
  description = "Base URL for API Gateway stage."

  value = module.APIGateway.base_url
}

output "create_url_endpoint" {
  description = "POST endpoint for creating a short URL"
  value       = module.APIGateway.create_url_endpoint
}

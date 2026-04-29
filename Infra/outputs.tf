output "cloudfront_domain_name" {
  value       = module.Cloudfront.cloudfront_domain_name
  description = "CloudFront domain name"
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

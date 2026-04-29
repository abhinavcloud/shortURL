
data "aws_region" "current" {}

output "cognito_domain" {
  value = "https://${aws_cognito_user_pool_domain.google_domain.domain}.auth.${data.aws_region.current.region}.amazoncognito.com"
}

output "cognito_client_id" {
  value = aws_cognito_user_pool_client.google_client.id
}

output "redirect_uri" {
  value = "https://${var.cloudfront_domain_name}"
}



output "google_authorized_redirect_uri" {
  value = "https://${aws_cognito_user_pool_domain.google_domain.domain}.auth.${data.aws_region.current.region}.amazoncognito.com/oauth2/idpresponse"
}

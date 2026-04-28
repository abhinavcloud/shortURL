resource "aws_cognito_user_pool" "google" {
  name                     = "google-pool"
  auto_verified_attributes = ["email"]
}

resource "aws_cognito_identity_provider" "google_provider" {
  user_pool_id  = aws_cognito_user_pool.google.id
  provider_name = "Google"
  provider_type = "Google"

  provider_details = {
    authorize_scopes = "email"
    client_id        = var.client_id
    client_secret    = var.client_secret
  }

  attribute_mapping = {
    email    = "email"
    username = "sub"
  }
}
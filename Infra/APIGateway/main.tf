resource "aws_apigatewayv2_api" "shorturl" {
  name          = "serverless_shorturl_gw"
  protocol_type = "HTTP"
  
  cors_configuration {
    allow_origins = [
      "https://${var.cloudfront_domain_name}",
      "http://localhost:3000"
    ]

    allow_methods = ["OPTIONS", "POST", "GET"]
    allow_headers = ["content-type", "authorization"]
    max_age       = 86400
  }

}

# JWT authorizer for Cognito User Pool
resource "aws_apigatewayv2_authorizer" "cognito_jwt" {
  api_id          = aws_apigatewayv2_api.shorturl.id
  name            = "cognito-jwt-authorizer"
  authorizer_type = "JWT"

  identity_sources = ["$request.header.Authorization"]

  jwt_configuration {
    issuer   = "https://cognito-idp.${var.region}.amazonaws.com/${var.cognito_user_pool_id}"
    audience = [var.cognito_client_id]
  }
}

resource "aws_apigatewayv2_stage" "shorturl" {
  api_id = aws_apigatewayv2_api.shorturl.id

  name        = "serverless_shorturl_stage"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }
}

#Lambda Integration : lambda_create_short_url

resource "aws_apigatewayv2_integration" "create_shorturl" {
  api_id = aws_apigatewayv2_api.shorturl.id

  integration_uri    = var.create_integration_uri
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.create_function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.shorturl.execution_arn}/*/*"
}




resource "aws_apigatewayv2_route" "create_short_url" {
  api_id = aws_apigatewayv2_api.shorturl.id

  route_key = "POST /createUrl"
  target    = "integrations/${aws_apigatewayv2_integration.create_shorturl.id}"

  
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_jwt.id

}


# Create API Gateway Integration with Lambda for GET /{shortUrlId}

resource "aws_apigatewayv2_integration" "get_short_url" {
  api_id = aws_apigatewayv2_api.shorturl.id

  integration_uri    = var.get_integration_uri
  integration_type   = "AWS_PROXY"
  integration_method = "GET"
}


# Create Lambda permission for GET /{shortUrlId} integration

resource "aws_lambda_permission" "api_gw_get_short_url" {
  statement_id  = "AllowExecutionFromAPIGatewayGetShortUrl"
  action        = "lambda:InvokeFunction"
  function_name = var.get_function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.shorturl.execution_arn}/*/GET/*"
}

# Create API Gateway Route for GET /{shortUrlId}

resource "aws_apigatewayv2_route" "get_short_url" {
  api_id = aws_apigatewayv2_api.shorturl.id

  route_key = "GET /r/{shortUrlId}"
  target    = "integrations/${aws_apigatewayv2_integration.get_short_url.id}"

  
  authorization_type = "NONE"
  
}

# CloudWatch Log Group for API Gateway Access Logs
resource "aws_cloudwatch_log_group" "api_gw" {
  name = "/aws/api_gw/${aws_apigatewayv2_api.shorturl.name}"

  retention_in_days = 30
}

resource "aws_apigatewayv2_api" "shorturl" {
  name          = "serverless_shorturl_gw"
  protocol_type = "HTTP"
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

resource "aws_apigatewayv2_integration" "shorturl" {
  api_id = aws_apigatewayv2_api.shorturl.id

  integration_uri    = var.integration_uri
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "create_short_url" {
  api_id = aws_apigatewayv2_api.shorturl.id

  route_key = "POST /createUrl"
  target    = "integrations/${aws_apigatewayv2_integration.shorturl.id}"
}

resource "aws_cloudwatch_log_group" "api_gw" {
  name = "/aws/api_gw/${aws_apigatewayv2_api.shorturl.name}"

  retention_in_days = 30
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.shorturl.execution_arn}/*/*"
}

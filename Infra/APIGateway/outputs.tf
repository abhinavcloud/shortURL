  output "base_url" {
    description = "Base URL for API Gateway stage."

    value = aws_apigatewayv2_stage.shorturl.invoke_url
  }

output "create_url_endpoint" {
  description = "POST endpoint for creating a short URL"
  value       = "${aws_apigatewayv2_stage.shorturl.invoke_url}/createUrl"
}

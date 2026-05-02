output "create_function_name" {
  description = "Name of the Lambda function."

  value = aws_lambda_function.lambda_create_short_url.function_name
}

output "create_integration_uri" {
    value = aws_lambda_function.lambda_create_short_url.invoke_arn

}

output "get_function_name" {
  description = "Name of the Lambda function for GET /{shortUrlId}."

  value = aws_lambda_function.lambda_get_short_url.function_name
}

output "get_integration_uri" {
    value = aws_lambda_function.lambda_get_short_url.invoke_arn

}

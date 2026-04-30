output "function_name" {
  description = "Name of the Lambda function."

  value = aws_lambda_function.lambda_create_short_url.function_name
}

output "integration_uri" {
    value = aws_lambda_function.lambda_create_short_url.invoke_arn

}
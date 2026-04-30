output "dynamodb_table_arn" {
    value = aws_dynamodb_table.short_urls.arn
}

output "dynamodb_table_name" {
    value = aws_dynamodb_table.short_urls.name
}



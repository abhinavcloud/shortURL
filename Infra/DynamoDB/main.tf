resource "aws_dynamodb_table" "short_urls" {
  name         = "synamodb-short-urls"
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "short_code"

  attribute {
    name = "short_code"
    type = "S"
  }

   point_in_time_recovery {
    enabled = true
  }

}

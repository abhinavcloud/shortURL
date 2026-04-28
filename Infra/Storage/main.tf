# Create a bucket to hold the lambda function code for createShortURL

data "archive_file" "lambda_create_short_url" {
  type = "zip"

  source_dir  = "../Code/lambda_create_short_url"
  output_path = "${path.module}/create_short_url.zip"
}

resource "aws_s3_bucket" "lambda_create_short_url" {
  bucket = "lambda_create_short_url"
}

resource "aws_s3_object" "lambda_create_short_url" {
  bucket = aws_s3_bucket.lambda_create_short_url.id

  key    = "create_short_url.zip"
  source = data.archive_file.lambda_create_short_url.output_path

  etag = filemd5(data.archive_file.lambda_create_short_url.output_path)
}

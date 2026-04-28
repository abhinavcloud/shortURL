# Create a bucket to host the frontend website UI

resource "aws_s3_bucket" "site" {
  bucket = "shorturl-website-landing-page"
  force_destroy = true

}

resource "aws_s3_bucket_public_access_block" "site" {
  bucket = aws_s3_bucket.site.id
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}


resource "aws_s3_bucket_ownership_controls" "site" {
  bucket = aws_s3_bucket.site.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}


# Create a bucket to hold the lambda function code for createShortURL

# Archiving the createShortURL Python code into a zip file
data "archive_file" "lambda_create_short_url" {
  type = "zip"

  source_dir  = "../Code/lambda_create_short_url"
  output_path = "../Code/create_short_url.zip"
}

# Creating a s3 bucket to hold the zip file

resource "aws_s3_bucket" "lambda_create_short_url" {
  bucket = "lambda-short-url-code"
  force_destroy = true
}


# Putting the zip file in the s3 bucket
resource "aws_s3_object" "lambda_create_short_url" {
  bucket = aws_s3_bucket.lambda_create_short_url.id

  key    = "create_short_url.zip"
  source = data.archive_file.lambda_create_short_url.output_path

  etag = filemd5(data.archive_file.lambda_create_short_url.output_path)
}
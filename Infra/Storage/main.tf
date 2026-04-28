# Create a bucket to host the frontend website UI

resource "aws_s3_bucket" "site" {
  bucket = "shorturl-website-landing-page"

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


data "aws_iam_policy_document" "site_bucket_policy" {
  statement {
    sid    = "AllowCloudFrontReadOnly"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions   = ["s3:GetObject"]
    resources = ["${data.terraform_remote_state.storage.outputs.bucket_arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values = [
        "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${aws_cloudfront_distribution.site.id}"
      ]
    }
  }
}

resource "aws_s3_bucket_policy" "site" {
  bucket = data.terraform_remote_state.storage.outputs.bucket_name
  policy = data.aws_iam_policy_document.site_bucket_policy.json
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
}


# Putting the zip file in the s3 bucket
resource "aws_s3_object" "lambda_create_short_url" {
  bucket = aws_s3_bucket.lambda_create_short_url.id

  key    = "create_short_url.zip"
  source = data.archive_file.lambda_create_short_url.output_path

  etag = filemd5(data.archive_file.lambda_create_short_url.output_path)
}
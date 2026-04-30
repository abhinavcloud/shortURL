# IAM role for Lambda execution
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "example" {
  name               = "lambda_execution_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "archive_file" "lambda_create_short_url" {
  type = "zip"

  source_dir  = "../Code/lambda_create_short_url"
  output_path = "../Code/create_short_url.zip"
}



# Lambda function
resource "aws_lambda_function" "example" {
  filename      = data.archive_file.lambda_create_short_url.output_path
  function_name = "lambda_create_short_url"
  role          = aws_iam_role.example.arn
  handler       = "index.handler"
  code_sha256   = data.archive_file.example.output_base64sha256

  runtime = "nodejs20.x"

  environment {
    variables = {
      ENVIRONMENT = "production"
      LOG_LEVEL   = "info"
    }
  }

  tags = {
    Environment = "production"
    Application = "example"
  }
}
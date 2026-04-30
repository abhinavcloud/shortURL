# IAM role for Lambda execution
data "aws_iam_policy_document" "assume_role_lambda" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "lambda_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_lambda.json
}

data "archive_file" "lambda_create_short_url" {
  type = "zip"

  source_dir  = "../Code/lambda_create_short_url"
  output_path = "../Code/create_short_url.zip"
}



# Lambda function
resource "aws_lambda_function" "lambda_create_short_url" {
  filename      = data.archive_file.lambda_create_short_url.output_path
  function_name = "lambda_create_short_url"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_create_short_url.lambda_handler"
  code_sha256   = data.archive_file.lambda_create_short_url.output_base64sha256

  runtime = "python3.12"

  environment {
    variables = {
      ENVIRONMENT = "production"
      LOG_LEVEL   = "info"
      TABLE_NAME = "${var.dynamodb_table_name}"
      DOMAIN_NAME = "https://${var.cloudfront_domain_name}"

    }
  }

  tags = {
    Environment = "production"
    Application = "example"
  }
}


resource "aws_cloudwatch_log_group" "lambda_create_short_url" {
  name = "/aws/lambda/${aws_lambda_function.lambda_create_short_url.function_name}"

  retention_in_days = 30
}


resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "lambda_dynamodb_policy" {
  name        = "lambda-dynamodb"
  description = "Allow Lambda to access DynamoDB short URL table"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DynamoDBAccess"
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = [
          "${var.dynamodb_table_arn}",
          "${var.dynamodb_table_arn}/index/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_attach_dynamodb" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_dynamodb_policy.arn
}

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
  handler       = "index.handler"
  code_sha256   = data.archive_file.lambda_create_short_url.output_base64sha256

  runtime = "python3.12"

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


resource "aws_cloudwatch_log_group" "lambda_create_short_url" {
  name = "/aws/lambda/${aws_lambda_function.lambda_create_short_url.function_name}"

  retention_in_days = 30
}


resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
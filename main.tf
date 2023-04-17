terraform {
  required_version = ">= 0.12"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.26"
    }
  }
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

provider "aws" {
  region                   = var.aws_region
  profile                  = "testing"
  shared_credentials_files = ["$HOME/.aws/credentials"]
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "main.py"
  output_path = "main.zip"
}

resource "aws_lambda_function" "mypython_lambda" {
  filename         = "main.zip"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  function_name    = "python_lambda_test"
  role             = aws_iam_role.python_lambda_role.arn
  handler          = "main.lambda_handler"
  runtime          = "python3.8"
}

resource "aws_iam_role" "python_lambda_role" {
  name               = "python_role"
  assume_role_policy = <<EOF
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Sid": "",
			"Effect": "Allow",
			"Principal": {
				"Service": [
					"lambda.amazonaws.com"
				]
			},
			"Action": "sts:AssumeRole"
		}
	]
}
EOF
}

resource "aws_dynamodb_table" "mood-dynamodb-table" {
  name           = "Mood"
  billing_mode   = "PROVISIONED"
  read_capacity  = 2
  write_capacity = 2
  hash_key       = "Email"
  range_key      = "Datetime"

  attribute {
    name = "Email"
    type = "S"
  }

  attribute {
    name = "Datetime"
    type = "S"
  }
}

resource "aws_iam_role_policy" "python_lambda_dynamodb" {
  role = aws_iam_role.python_lambda_role.name

  policy = jsonencode({
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : ["dynamodb:*"],
        "Resource" : [aws_dynamodb_table.mood-dynamodb-table.arn],
      },
    ],
  })
}

resource "aws_apigatewayv2_api" "mood_api" {
  name          = "mood_http_api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "mood_integration" {
  api_id           = aws_apigatewayv2_api.mood_api.id
  integration_type = "AWS_PROXY"

  connection_type      = "INTERNET"
  description          = "Lambda example"
  integration_method   = "POST"
  integration_uri      = aws_lambda_function.mypython_lambda.invoke_arn
  passthrough_behavior = "WHEN_NO_MATCH"
}

resource "aws_apigatewayv2_route" "mood_route" {
  api_id    = aws_apigatewayv2_api.mood_api.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.mood_integration.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.mood_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "api_lambda_permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.mypython_lambda.arn
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.mood_api.execution_arn}/*/*"
}

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

data "archive_file" "lambda_get_zip" {
  type        = "zip"
  source_file = "get_mood.py"
  output_path = "get_mood.zip"
}

resource "aws_lambda_function" "get_mood_lambda" {
  filename         = "get_mood.zip"
  source_code_hash = data.archive_file.lambda_get_zip.output_base64sha256
  function_name    = "python_lambda_get"
  role             = aws_iam_role.python_lambda_role.arn
  handler          = "get_mood.lambda_handler"
  runtime          = "python3.8"
}

data "archive_file" "lambda_post_zip" {
  type        = "zip"
  source_file = "post_mood.py"
  output_path = "post_mood.zip"
}

resource "aws_lambda_function" "post_mood_lambda" {
  filename         = "post_mood.zip"
  source_code_hash = data.archive_file.lambda_post_zip.output_base64sha256
  function_name    = "python_lambda_post"
  role             = aws_iam_role.python_lambda_role.arn
  handler          = "post_mood.lambda_handler"
  runtime          = "python3.8"
}

resource "aws_iam_role" "python_lambda_role" {
  name = "python_role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : [
            "lambda.amazonaws.com"
          ]
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_cloudwatch" {
  role = aws_iam_role.python_lambda_role.name

  policy = jsonencode({
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents",
          "logs:GetLogEvents",
          "logs:FilterLogEvents"
        ],
        "Resource" : "*"
      },
    ],
  })
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

resource "aws_iam_role" "api_gateway_role" {
  name = "gateway_role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : [
            "apigateway.amazonaws.com"
          ]
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "api_gateway_lambda" {
  role = aws_iam_role.api_gateway_role.name

  policy = jsonencode({
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : "lambda:InvokeFunction",
        "Resource" : "*"
      },
    ],
  })
}

resource "aws_iam_role_policy" "api_gateway_cloudwatch" {
  role = aws_iam_role.api_gateway_role.name

  policy = jsonencode({
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents",
          "logs:GetLogEvents",
          "logs:FilterLogEvents"
        ],
        "Resource" : "*"
      },
    ],
  })
}

resource "aws_apigatewayv2_api" "mood_api" {
  name          = "mood_http_api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "mood_get_integration" {
  api_id           = aws_apigatewayv2_api.mood_api.id
  integration_type = "AWS_PROXY"

  connection_type      = "INTERNET"
  description          = "dynamodb read mood"
  integration_method   = "POST"
  integration_uri      = aws_lambda_function.get_mood_lambda.invoke_arn
  passthrough_behavior = "WHEN_NO_MATCH"
}

resource "aws_apigatewayv2_integration" "mood_post_integration" {
  api_id           = aws_apigatewayv2_api.mood_api.id
  integration_type = "AWS_PROXY"

  connection_type      = "INTERNET"
  description          = "dynamodb write mood"
  integration_method   = "POST"
  integration_uri      = aws_lambda_function.post_mood_lambda.invoke_arn
  passthrough_behavior = "WHEN_NO_MATCH"
}

resource "aws_apigatewayv2_route" "mood_get_route" {
  api_id    = aws_apigatewayv2_api.mood_api.id
  route_key = "GET /mood"
  target    = "integrations/${aws_apigatewayv2_integration.mood_get_integration.id}"
}

resource "aws_apigatewayv2_route" "mood_post_route" {
  api_id    = aws_apigatewayv2_api.mood_api.id
  route_key = "POST /mood"
  target    = "integrations/${aws_apigatewayv2_integration.mood_post_integration.id}"
}

resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "api_gateway_logs_${aws_apigatewayv2_api.mood_api.id}"
  retention_in_days = 7
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.mood_api.id
  name        = "$default"
  auto_deploy = true
  depends_on  = [aws_cloudwatch_log_group.api_gateway_logs]
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_logs.arn
    format          = "$context.extendedRequestId $context.identity.sourceIp $context.identity.caller $context.identity.user [$context.requestTime] $context.httpMethod $context.resourcePath $context.protocol $context.status $context.responseLength $context.requestId"
  }
}

resource "aws_lambda_permission" "api_get_lambda_permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_mood_lambda.arn
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.mood_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "api_post_lambda_permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.post_mood_lambda.arn
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.mood_api.execution_arn}/*/*"
}

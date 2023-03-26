terraform {
	required_version = ">= 0.12"

	required_providers {
		aws = {
			source = "hashicorp/aws"
			version = ">= 3.26"
		}
	}
}

variable "aws_region" {
	type = string
	default = "us-east-1"
}

provider "aws" {
	region = var.aws_region
	profile = "testing"
	shared_credentials_files = ["$HOME/.aws/credentials"]
}

data "archive_file" "zip" {
	type = "zip"
	source_file = "main.py"
	output_path = "main.zip"
}

resource "aws_lambda_function" "mypython_lambda" {
	filename = "main.zip"
	function_name = "python_lambda_test"
	role = aws_iam_role.python_lambda_role.arn
	handler = "lambda_handler"
	runtime = "python3.8"
}

resource "aws_iam_role" "python_lambda_role" {
	name = "python_role"
	assume_role_policy = <<EOF
	{
		"Version": "2012-10-17",
		"Statement": [
			{
				"Action": "sts:AssumeRole",
				"Principal": {
					"Service": "lambda.amazonaws.com"
				},
				"Effect": "Allow",
				"Sid": " "
			}
		]
	}
	EOF
}

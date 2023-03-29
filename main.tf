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

data "archive_file" "lambda_zip" {
	type = "zip"
	source_file = "main.py"
	output_path = "main.zip"
}

resource "aws_lambda_function" "mypython_lambda" {
	filename = "main.zip"
	source_code_hash = data.archive_file.lambda_zip.output_base64sha256
	function_name = "python_lambda_test"
	role = aws_iam_role.python_lambda_role.arn
	handler = "main.lambda_handler"
	runtime = "python3.8"
}

resource "aws_iam_role" "python_lambda_role" {
	name = "python_role"
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

import boto3
import datetime
import json

client = boto3.client("dynamodb")


def get_mood(email):
	return {
		"statusCode": 200,
		"body": json.dumps("get mood result placeholder")
	}

def lambda_handler(event, context):
	params = event.get("queryStringParameters") or {} #  queryStringParameters value can be None
	if "email" in params:
		return get_mood(params["email"])
	return {
		"statusCode": 200,
		"body": json.dumps("get moods result placeholder")
	}

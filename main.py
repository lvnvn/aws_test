import boto3
import datetime
import json

client = boto3.client("dynamodb")

def lambda_handler(event, context):
	current_time = datetime.datetime.now().strftime("%m.%d.%Y, %H:%M")
	mood = event["queryStringParameters"]["mood"]
	data = client.put_item(
		TableName="Mood",
		Item={
			"Email": {"S": "123abc@gmail.com"},
			"Datetime": {"S": current_time},
			"Mood": {"S": mood},
		}
	)

	return {
		"statusCode": 200,
		"body": json.dumps(f"you felt {mood} at {current_time}")
	}

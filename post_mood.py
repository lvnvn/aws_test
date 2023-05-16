import boto3
import datetime
import json
from json.decoder import JSONDecodeError

client = boto3.client("dynamodb")


def lambda_handler(event, context):
	body = {}
	if json_body := event.get("body"):
		try:
			body = json.loads(json_body)
		except JSONDecodeError as e:
			return {
				"statusCode": 400,
				"body": f"JSONDecodeError in ({json_body}): {e}",
			}

	mood = body.get("mood") #  TODO: type validation
	email = body.get("email") #  TODO: type validation

	if not mood:
		return {
			"statusCode": 400,
			"body": "mood parameter is required",
		}

	current_time = datetime.datetime.now().strftime("%m.%d.%Y, %H:%M")
	client.put_item(
		TableName="Mood",
		Item={
			"Email": {"S": email},
			"EntryTime": {"S": current_time},
			"Mood": {"S": mood},
		}
	)

	return {
		"statusCode": 200,
		"body": json.dumps(f"you felt {mood} at {current_time}")
	}

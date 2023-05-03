import boto3
import datetime
import json

client = boto3.client("dynamodb")


def get_mood(email):
	return {
		"statusCode": 200,
		"body": json.dumps("get mood result placeholder")
	}

def get_moods(event):
	params = event.get("queryStringParameters") or {} #  queryStringParameters value can be None
	if "email" in params:
		return get_mood(params["email"])
	return {
		"statusCode": 200,
		"body": json.dumps("get moods result placeholder")
	}

def post_mood(event):
	body = {}
	if b := event.get("body"):
		body = json.loads(b)
	mood = body.get("mood") #  TODO: type validation

	if not mood:
		return {
			"statusCode": 400,
			"body": "mood parameter is required",
		}

	current_time = datetime.datetime.now().strftime("%m.%d.%Y, %H:%M")
	client.put_item(
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

def lambda_handler(event, context):
	path = event.get("path")
	method = event.get("httpMethod")

	if path == "/mood":
		if method == "GET":
			return get_moods(event)
		if method == "POST":
			return post_mood(event)

	return {
		"statusCode": 200,
		"body": json.dumps(f"unsupported method") # TODO: return proper error code
	}

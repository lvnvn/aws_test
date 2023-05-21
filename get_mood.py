import boto3
import datetime
import json

client = boto3.client("dynamodb")

def get_mood(email):
	entry = client.get_item(
		TableName="Mood",
		Key={'Email': email}
	)
	return {
		"statusCode": 200,
		"body": json.dumps(entry)
	}

def get_moods():
	items = client.scan(TableName="Mood", ProjectionExpression="Mood, EntryTime")["Items"]
	result = {}
	for i, item in enumerate(items):
		mood = item.get("Mood")
		entry_time = item.get("EntryTime")
		result[i] = f"{mood} at {entry_time}"

	return {
		"statusCode": 200,
		"body": json.dumps(result)
	}

def lambda_handler(event, context):
	params = event.get("queryStringParameters") or {} #  queryStringParameters value can be None
	if "email" in params:
		return get_mood(params["email"])
	else:
		return get_moods()
	return {
		"statusCode": 200,
		"body": json.dumps("get moods result placeholder")
	}

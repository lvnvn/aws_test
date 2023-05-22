import boto3
import datetime
import json
from boto3.dynamodb.conditions import Key

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('Mood')

def make_response(items):
	result = {}
	for i, item in enumerate(items):
		mood = item.get("Mood")
		entry_time = item.get("EntryTime")
		result[i] = f"{mood} at {entry_time}"
	return result

def get_moods_for_user(email):
	items = table.query(KeyConditionExpression=Key('Email').eq(email)).get('Items', [])
	return {
		"statusCode": 200,
		"body": json.dumps(make_response(items))
	}

def get_moods():
	items = table.scan(ProjectionExpression="Mood, EntryTime")["Items"]
	return {
		"statusCode": 200,
		"body": json.dumps(make_response(items))
	}

def lambda_handler(event, context):
	params = event.get("queryStringParameters") or {} #  queryStringParameters value can be None
	if "email" in params:
		return get_moods_for_user(params["email"])
	else:
		return get_moods()
	return {
		"statusCode": 200,
		"body": json.dumps("get moods result placeholder")
	}

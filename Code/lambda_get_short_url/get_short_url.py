import os
import boto3
from botocore.exceptions import ClientError
from urllib.parse import unquote

dynamodb = boto3.resource("dynamodb")
TABLE_NAME = os.environ["TABLE_NAME"]
table = dynamodb.Table(TABLE_NAME)

def handler(event, context):
    path_params = event.get("pathParameters") or {}

    # Correct name based on your API route: /r/{shortUrlId}
    short_code = path_params.get("shortUrlId")

    # Fallback: if pathParameters isn't present for some reason, parse rawPath
    # rawPath would look like: "/r/2ULu0Li"
    if not short_code:
        raw_path = event.get("rawPath") or event.get("path") or ""
        parts = raw_path.strip("/").split("/")  # ["r", "2ULu0Li"]
        if len(parts) >= 2 and parts[0] == "r":
            short_code = parts[1]
        elif len(parts) >= 1:
            short_code = parts[0]

    if not short_code:
        return {
            "statusCode": 400,
            "headers": {"content-type": "text/plain"},
            "body": "Missing short code"
        }

    short_code = unquote(short_code)

    try:
        resp = table.get_item(Key={"short_code": short_code})
        item = resp.get("Item")

        if not item:
            return {
                "statusCode": 404,
                "headers": {"content-type": "text/plain", "Cache-Control": "no-store"},
                "body": "Short URL not found"
            }

        long_url = item.get("long_url")
        if not long_url:
            return {
                "statusCode": 500,
                "headers": {"content-type": "text/plain", "Cache-Control": "no-store"},
                "body": "Invalid record: long_url missing"
            }

        if not (long_url.startswith("http://") or long_url.startswith("https://")):
            long_url = "https://" + long_url

        # Redirect
        return {
            "statusCode": 302,  # use 301 only if you want permanent
            "headers": {
                "Location": long_url,
                "Cache-Control": "no-store"  # safest while building
            },
            "body": ""
        }

    except ClientError as e:
        return {
            "statusCode": 500,
            "headers": {"content-type": "text/plain", "Cache-Control": "no-store"},
            "body": f"DynamoDB error: {str(e)}"
        }
import json
import os
import hashlib
import boto3
from botocore.exceptions import ClientError
from datetime import datetime, timezone

# Initialize DynamoDB client
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["TABLE_NAME"])

# Base62 alphabet (0-9, a-z, A-Z)
CHARSET = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

def encode_base62(num: int) -> str:
    """Converts an integer to a Base62 string."""
    if num == 0:
        return CHARSET[0]
    arr = []
    while num:
        num, rem = divmod(num, 62)
        arr.append(CHARSET[rem])
    arr.reverse()
    return "".join(arr)

def cors_headers():
    return {
        "Access-Control-Allow-Origin": "*",  # tighten later to CloudFront domain
        "Access-Control-Allow-Headers": "Content-Type,Authorization",
        "Access-Control-Allow-Methods": "OPTIONS,POST",
        "Content-Type": "application/json",
    }

def response(status_code: int, body: dict):
    return {
        "statusCode": status_code,
        "headers": cors_headers(),
        "body": json.dumps(body),
    }

def get_method(event):
    # HTTP API v2: requestContext.http.method
    # REST API v1: httpMethod
    return (event.get("requestContext", {}).get("http", {}).get("method")
            or event.get("httpMethod")
            or "")

def get_user_sub(event):
    """
    HTTP API v2 JWT authorizer:
      requestContext.authorizer.jwt.claims.sub
    REST API v1 Cognito authorizer:
      requestContext.authorizer.claims.sub
    """
    # HTTP API v2
    claims = (event.get("requestContext", {})
                  .get("authorizer", {})
                  .get("jwt", {})
                  .get("claims", {}))
    if isinstance(claims, dict) and claims.get("sub"):
        return claims.get("sub")

    # REST API v1
    claims = (event.get("requestContext", {})
                  .get("authorizer", {})
                  .get("claims", {}))
    if isinstance(claims, dict) and claims.get("sub"):
        return claims.get("sub")

    return "anonymous"

def lambda_handler(event, context):
    # 0) CORS preflight
    if get_method(event).upper() == "OPTIONS":
        return {
            "statusCode": 204,
            "headers": cors_headers(),
            "body": ""
        }

    # 1) Parse Input
    try:
        raw_body = event.get("body") or "{}"
        body = json.loads(raw_body) if isinstance(raw_body, str) else raw_body
        long_url = (body.get("long_url") or "").strip()
    except (json.JSONDecodeError, TypeError):
        return response(400, {"error": "Invalid request body"})

    # 2) Validation
    if not long_url.startswith(("http://", "https://")):
        return response(400, {"error": "A valid URL starting with http/https is required"})

    # 3) Generate Short Code
    url_hash = hashlib.md5(long_url.encode("utf-8")).hexdigest()
    short_code = encode_base62(int(url_hash[:8], 16))

    # 4) Get user_id from authorizer claims (safe for HTTP API v2 + REST v1)
    user_id = get_user_sub(event)

    # 5) Save to DynamoDB
    try:
        table.put_item(
            Item={
                "short_code": short_code,
                "long_url": long_url,
                "user_id": user_id,
                "created_at": datetime.now(timezone.utc).isoformat(),
            },
            ConditionExpression="attribute_not_exists(short_code)"
        )
    except ClientError as e:
        if e.response["Error"]["Code"] == "ConditionalCheckFailedException":
            # short_code already exists; for now we just return the same short_code
            pass
        else:
            return response(500, {"error": "Database error"})

    # 6) Return Response
    domain = (os.environ.get("DOMAIN_NAME") or "https://my.link").rstrip("/")
    return response(201, {
        "short_url": f"{domain}/{short_code}",
        "short_code": short_code
    })
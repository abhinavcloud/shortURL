import json
import os
import hashlib
import boto3
from botocore.exceptions import ClientError

# Initialize DynamoDB client
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['TABLE_NAME'])

# Base62 alphabet (0-9, a-z, A-Z)
CHARSET = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

def encode_base62(num):
   """Converts an integer to a Base62 string."""
   if num == 0:
       return CHARSET[0]
   arr = []
   while num:
       num, rem = divmod(num, 62)
       arr.append(CHARSET[rem])
   arr.reverse()
   return ''.join(arr)

def lambda_handler(event, context):
   # 1. Parse Input
   try:
       body = json.loads(event.get('body', '{}'))
       long_url = body.get('long_url')
   except (json.JSONDecodeError, TypeError):
       return {'statusCode': 400, 'body': json.dumps({'error': 'Invalid request body'})}

   # 2. Validation
   if not long_url or not long_url.startswith(('http://', 'https://')):
       return {'statusCode': 400, 'body': json.dumps({'error': 'A valid URL starting with http/https is required'})}

   # 3. Generate Short Code
   # We hash the URL and take a portion of it to generate a 6-7 character code
   url_hash = hashlib.md5(long_url.encode('utf-8')).hexdigest()
   # Convert hex slice to int, then to Base62
   short_code = encode_base62(int(url_hash[:8], 16))

   # 4. Save to DynamoDB
   try:
       table.put_item(
           Item={
               'short_code': short_code,
               'long_url': long_url,
               'user_id': event['requestContext']['authorizer']['claims']['sub'], # From Cognito
               'created_at': context.aws_request_id
           },
           # Optional: Condition to avoid unnecessary writes if short_code exists
           ConditionExpression='attribute_not_exists(short_code)'
       )
   except ClientError as e:
       if e.response['Error']['Code'] == 'ConditionalCheckFailedException':
           # This is fine; the URL mapping already exists
           pass
       else:
           return {'statusCode': 500, 'body': json.dumps({'error': 'Database error'})}

   # 5. Return Response
   domain = os.environ.get('DOMAIN_NAME', 'https://my.link')
   return {
       'statusCode': 201,
       'headers': {
           'Access-Control-Allow-Origin': '*', # Adjust for production
           'Content-Type': 'application/json'
       },
       'body': json.dumps({
           'short_url': f"{domain}/{short_code}",
           'short_code': short_code
       })
   }
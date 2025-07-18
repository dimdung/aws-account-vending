import boto3
import os
import logging

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

org_client = boto3.client('organizations')
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.getenv('METADATA_TABLE', 'AccountMetadata'))
ses_client = boto3.client('ses')
sender_email = os.getenv('SENDER_EMAIL', 'provisioner@yourdomain.com')

def lambda_handler(event, context):
    try:
        logger.info("Starting account status checks")
        
        # Get all in-progress requests
        response = table.scan(
            FilterExpression='#status = :status',
            ExpressionAttributeNames={'#status': 'status'},
            ExpressionAttributeValues={':status': 'CREATING'}
        )
        
        logger.info(f"Found {len(response.get('Items', []))} accounts to check")
        
        for item in response.get('Items', []):
            process_account(item)
            
        return {
            'statusCode': 200,
            'body': f"Processed {len(response.get('Items', []))} accounts"
        }
        
    except Exception as e:
        logger.error(f"Error in status checker: {str(e)}")
        return {
            'statusCode': 500,
            'body': str(e)
        }

def process_account(item):
    try:
        logger.info(f"Processing account {item.get('accountId')}")
        
        status_response = org_client.describe_create_account_status(
            CreateAccountRequestId=item['accountId']
        )
        
        status = status_response['CreateAccountStatus']['State']
        account_id = status_response['CreateAccountStatus'].get('AccountId')
        
        if status == 'SUCCEEDED' and account_id:
            logger.info(f"Account {account_id} creation succeeded")
            
            # Update account ID if not already set
            if item.get('accountId') != account_id:
                table.update_item(
                    Key={'requestId': item['requestId']},
                    UpdateExpression='SET accountId = :accountId',
                    ExpressionAttributeValues={':accountId': account_id}
                )
            
            # Move account to target OU
            org_client.move_account(
                AccountId=account_id,
                SourceParentId=item['ouId'],
                DestinationParentId=item['ouId']
            )
            
            # Update status
            table.update_item(
                Key={'requestId': item['requestId']},
                UpdateExpression='SET #status = :status',
                ExpressionAttributeNames={'#status': 'status'},
                ExpressionAttributeValues={':status': 'ACTIVE'}
            )
            
            # Send success notification
            send_notification(
                item['accountEmail'],
                'SUCCESS',
                f"AWS Account {item['accountName']} ({account_id}) created successfully in OU {item['ouName']}"
            )
            
        elif status == 'FAILED':
            logger.error(f"Account creation failed for request {item['requestId']}")
            
            failure_reason = status_response['CreateAccountStatus'].get('FailureReason', 'Unknown')
            table.update_item(
                Key={'requestId': item['requestId']},
                UpdateExpression='SET #status = :status, failureReason = :reason',
                ExpressionAttributeNames={'#status': 'status'},
                ExpressionAttributeValues={
                    ':status': 'FAILED',
                    ':reason': failure_reason
                }
            )
            
            send_notification(
                item['accountEmail'],
                'FAILED',
                f"AWS Account {item['accountName']} creation failed. Reason: {failure_reason}"
            )
            
    except Exception as e:
        logger.error(f"Error processing account {item.get('accountId')}: {str(e)}")

def send_notification(recipient, status, message):
    try:
        subject = f"AWS Account Provisioning - {status}"
        
        ses_client.send_email(
            Source=sender_email,
            Destination={'ToAddresses': [recipient]},
            Message={
                'Subject': {'Data': subject},
                'Body': {
                    'Text': {'Data': message},
                    'Html': {'Data': f"<p>{message}</p>"}
                }
            }
        )
        logger.info(f"Sent {status} notification to {recipient}")
    except Exception as e:
        logger.error(f"Failed to send notification: {str(e)}")

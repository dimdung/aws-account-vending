import boto3
import uuid
from datetime import datetime
import os

org_client = boto3.client('organizations')
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.getenv('METADATA_TABLE', 'AccountMetadata'))
ses_client = boto3.client('ses')

def lambda_handler(event, context):
    try:
        # Input validation
        required_fields = ['accountName', 'accountEmail', 'ouName']
        if not all(field in event for field in required_fields):
            return {
                'statusCode': 400,
                'body': 'Missing required fields. Need accountName, accountEmail, and ouName'
            }
        
        account_name = event['accountName']
        account_email = event['accountEmail']
        ou_name = event['ouName']
        metadata = event.get('metadata', {})
        
        request_id = str(uuid.uuid4())
        root_id = os.getenv('ORG_ROOT_ID', 'r-xxxx')  # Set this in Lambda env vars
        
        ou_id = get_or_create_ou(ou_name, root_id)
        
        create_response = org_client.create_account(
            Email=account_email,
            AccountName=account_name,
            RoleName='OrganizationAccountAccessRole',
            IamUserAccessToBilling='DENY'
        )
        
        metadata_item = {
            'requestId': request_id,
            'accountId': create_response['CreateAccountStatus']['AccountId'],
            'accountName': account_name,
            'accountEmail': account_email,
            'ouName': ou_name,
            'ouId': ou_id,
            'status': 'CREATING',
            'createdAt': datetime.now().isoformat(),
            'metadata': metadata
        }
        
        table.put_item(Item=metadata_item)
        
        return {
            'statusCode': 200,
            'body': {
                'requestId': request_id,
                'accountId': create_response['CreateAccountStatus']['AccountId'],
                'status': 'IN_PROGRESS',
                'message': 'Account creation initiated'
            }
        }
        
    except Exception as e:
        return {
            'statusCode': 500,
            'body': f"Error: {str(e)}"
        }

def get_or_create_ou(ou_name, parent_id):
    try:
        paginator = org_client.get_paginator('list_organizational_units_for_parent')
        for page in paginator.paginate(ParentId=parent_id):
            for ou in page['OrganizationalUnits']:
                if ou['Name'].lower() == ou_name.lower():
                    return ou['Id']
        
        create_response = org_client.create_organizational_unit(
            ParentId=parent_id,
            Name=ou_name
        )
        return create_response['OrganizationalUnit']['Id']
    except Exception as e:
        raise Exception(f"OU operation failed: {str(e)}")

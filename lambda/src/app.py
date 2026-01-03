import boto3
import os
from datetime import datetime, timezone

def Happy_new_year(event, context):
    iam = boto3.client('iam')
    ses = boto3.client('ses')
    
    # 1. Configuration
    # We will now audit ALL users to make this a professional tool
    sender = os.environ.get('SENDER_EMAIL', 'srivishnukosuri94@gmail.com')
    recipient = 'vishnu.kosuri121212@gmail.com'
    
    print(f"--- Starting Daily Security Audit: {datetime.now()} ---")

    try:
        # Step: Get all users in the account so we don't have to hardcode names
        users_response = iam.list_users()
        
        for user in users_response['Users']:
            target_user = user['UserName']
            
            # Step: Get keys for this specific user
            keys_response = iam.list_access_keys(UserName=target_user)
            
            for key in keys_response['AccessKeyMetadata']:
                key_id = key['AccessKeyId']
                creation_date = key['CreateDate']
                
                # Step: Calculate Age
                now = datetime.now(timezone.utc)
                age_delta = now - creation_date
                days_old = age_delta.days
                
                # LOGIC: Trigger EVERY DAY if the key exists (age >= 0)
                # This ensures an email goes out every time the Lambda runs
                if days_old >= 0:
                    print(f"Match! User: {target_user} | Key: {key_id} | Age: {days_old} days")
                    
                    iam_url = f"https://console.aws.amazon.com/iam/home#/users/{target_user}?section=security_credentials"
                    subject = f"DAILY REMINDER: Rotate AWS Key (Age: {days_old} Days)"
                    email_body = (
                        f"Hello {target_user},\n\n"
                        f"This is your daily security reminder.\n"
                        f"Your Access Key {key_id} is now {days_old} days old.\n"
                        f"Please rotate your keys at: {iam_url}\n\n"
                        f"Best regards,\nAutomated Security Bot"
                    )
                    
                    # Step: Trigger SES
                    ses.send_email(
                        Source=sender,
                        Destination={'ToAddresses': [recipient]},
                        Message={
                            'Subject': {'Data': subject},
                            'Body': {'Text': {'Data': email_body}}
                        }
                    )
                    print(f"Email sent for {target_user}")

        return {'statusCode': 200, 'body': 'Daily Audit Complete'}

    except Exception as e:
        print(f"Error: {str(e)}")
        return {'statusCode': 500, 'body': str(e)}

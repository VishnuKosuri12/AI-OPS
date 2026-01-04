import boto3
import os
import portals  # Importing your portal logic from portals.py
from datetime import datetime

def Happy_new_year(event, context):
    # Hard-coding region to us-east-1 for both local and cloud consistency
    iam = boto3.client('iam', region_name='us-east-1')
    ses = boto3.client('ses', region_name='us-east-1')
    
    # Configuration
    target_user = 'vishnu.kosuri121212@gmail.com'
    sender = os.environ.get('SENDER_EMAIL', 'srivishnukosuri94@gmail.com')
    bucket_name = "vishnu-pooja-storage-2025"

    print(f"--- Starting Secure Portal Link Generation for: {target_user} ---")

    try:
        # 1. Get the Access Key from IAM to include in the email
        print("Step 1: Auditing IAM Keys...")
        key_response = iam.list_access_keys(UserName=target_user)
        user_key_id = key_response['AccessKeyMetadata'][0]['AccessKeyId']

        # 2. Generate the Secure S3 Upload Link via portals.py
        print("Step 2: Generating Pre-signed URL...")
        timestamp = datetime.now().strftime("%Y_%m_%d_%H%M")
        suggested_file = f"upload_{timestamp}.txt"
        upload_link = portals.generate_upload_link(bucket_name, suggested_file)

        if not upload_link:
            raise Exception("Failed to generate S3 Pre-signed URL")

        # 3. Create the Email Body
        subject = "ACTION REQUIRED: Your Secure S3 Upload Link & Access Key"
        body = f"""
        Hello,

        Your Security Audit is complete. 
        
        IDENTITY VERIFIED:
        Access Key ID: {user_key_id}

        SECURE UPLOAD LINK:
        {upload_link}

        INSTRUCTIONS:
        1. This is a 'PUT' link for uploading data to the 'Analyze/' folder.
        2. It is valid for 1 hour.
        3. To test this link, use the following CURL command in your terminal:
           curl -X PUT -T "your_file.txt" "{upload_link}"

        Regards,
        Vishnu-Pooja Security Bot
        """

        # 4. Send the Email
        print("Step 3: Sending SES Email...")
        ses.send_email(
            Source=sender,
            Destination={'ToAddresses': [target_user]},
            Message={
                'Subject': {'Data': subject},
                'Body': {'Text': {'Data': body}}
            }
        )

        print(f"SUCCESS: Email sent to {target_user} with Key {user_key_id}")
        return {'statusCode': 200, 'body': 'Process completed successfully'}

    except Exception as e:
        print(f"CRITICAL ERROR: {str(e)}")
        return {'statusCode': 500, 'body': str(e)}

# --- LOCAL EXECUTION TRIGGER ---
# This part tells Python to run the function when you type 'python app.py'
if __name__ == "__main__":
    print("DEBUG: Script Started Manually")
    Happy_new_year(None, None)
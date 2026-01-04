import boto3
from botocore.exceptions import ClientError

def generate_upload_link(bucket_name, file_name, expiration=3600):
    """
    Generates a pre-signed URL that allows a user to UPLOAD a file
    to a specific S3 path even if they don't have AWS keys.
    """
    s3_client = boto3.client('s3', region_name='us-east-1')
    object_key = f"Analyze/{file_name}"
    
    try:
        # We use 'put_object' so the link allows an UPLOAD
        response = s3_client.generate_presigned_url(
            'put_object',
            Params={'Bucket': bucket_name, 'Key': object_key},
            ExpiresIn=expiration
        )
        return response
    except ClientError as e:
        print(f"Error generating presigned URL: {e}")
        return None

# Keep your existing vishnu_business_portal for local testing if you like
def vishnu_business_portal():
    # ... (Keep your original CLI code here for your own local use)
    pass

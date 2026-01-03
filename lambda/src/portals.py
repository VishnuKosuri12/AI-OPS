import boto3
from botocore.exceptions import ClientError
import os

def vishnu_business_portal():
    print("="*60)
    print("       VISHNU-POOJA SECURE S3 STORAGE INTERFACE        ")
    print("="*60)
    print("Status: Connected to AWS Infrastructure")
    print("Target Bucket: vishnu-pooja-storage-2025")
    print("Target Folder: Analyze/")
    print("-" * 60)

    # 1. AUTHENTICATION SECTION
    # The user enters the keys they received via your automated email
    print("\n[STEP 1: IDENTITY VERIFICATION]")
    user_access_key = input("Please enter your Access Key ID: ").strip()
    user_secret_key = input("Please enter your Secret Access Key: ").strip()

    # Configuration for the specific project folder
    BUCKET_NAME = "vishnu-pooja-storage-2025"
    PREFIX = "Analyze/"

    try:
        # Create a session using the external user's specific credentials
        session = boto3.Session(
            aws_access_key_id=user_access_key,
            aws_secret_access_key=user_secret_key,
            region_name="us-east-1"
        )
        s3 = session.client('s3')

        # 2. AUTHORIZATION CHECK
        # We attempt to list objects. If the IAM policy is wrong, this will fail.
        print(f"\n[STEP 2: AUTHORIZING ACCESS TO /{PREFIX}]...")
        
        # We only list objects that start with 'Analyze/'
        response = s3.list_objects_v2(Bucket=BUCKET_NAME, Prefix=PREFIX)

        if 'Contents' not in response:
            print(f"\n[!] Connection Successful! Folder '{PREFIX}' is currently empty.")
        else:
            print("\n[SUCCESS] Access Granted. Displaying Analyze Folder Contents:")
            print("=" * 40)
            for obj in response['Contents']:
                # Clean the display name (remove the prefix)
                display_name = obj['Key'].replace(PREFIX, "")
                if display_name: # Don't print the folder itself
                    size_kb = round(obj['Size'] / 1024, 2)
                    print(f"FILE: {display_name} | SIZE: {size_kb} KB")
            print("=" * 40)

        # 3. INTERACTIVE ACTIONS
        while True:
            print("\nAvailable Actions:")
            print("1. Upload a file to Analyze/")
            print("2. Download a file from Analyze/")
            print("3. Exit Portal")
            
            choice = input("\nSelect an action (1/2/3): ")

            if choice == '1':
                local_file = input("Enter the full path of the file to upload: ").strip('"')
                if os.path.exists(local_file):
                    file_name = os.path.basename(local_file)
                    s3.upload_file(local_file, BUCKET_NAME, f"{PREFIX}{file_name}")
                    print(f"\n[DONE] Successfully uploaded '{file_name}' to the cloud.")
                else:
                    print("\n[ERROR] Could not find that file on your computer.")
            
            elif choice == '2':
                remote_file = input("Enter the EXACT name of the file to download: ")
                local_destination = f"./downloaded_{remote_file}"
                try:
                    s3.download_file(BUCKET_NAME, f"{PREFIX}{remote_file}", local_destination)
                    print(f"\n[DONE] File saved to: {os.path.abspath(local_destination)}")
                except:
                    print("\n[ERROR] File not found in the Analyze folder.")

            elif choice == '3':
                print("\nLogging out. Goodbye!")
                break
            else:
                print("\nInvalid selection. Try again.")

    except ClientError as e:
        error_code = e.response['Error']['Code']
        print(f"\n[CRITICAL ACCESS ERROR] {error_code}")
        if error_code == 'AccessDenied':
            print("Check: Ensure your IAM Policy allows access to the 'Analyze' folder.")
        elif error_code in ['InvalidClientTokenId', 'SignatureDoesNotMatch']:
            print("Check: Your Access Key or Secret Key is incorrect.")
        else:
            print(f"Detail: {e}")

if __name__ == "__main__":
    vishnu_business_portal()

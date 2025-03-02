import os
from dotenv import load_dotenv
import boto3

# Load variables from a .env file
load_dotenv()  

# configure AWS sagemaker
AWS_REGION = os.environ.get('AWS_REGION', 'us-east-2')
AWS_ACCESS_KEY_ID = os.environ.get('AWS_ACCESS_KEY_ID')
AWS_SECRET_ACCESS_KEY = os.environ.get('AWS_SECRET_ACCESS_KEY')

sagemaker_runtime = boto3.client(
    'sagemaker-runtime',
    region_name=AWS_REGION,
    aws_access_key_id=AWS_ACCESS_KEY_ID,
    aws_secret_access_key=AWS_SECRET_ACCESS_KEY
)

ENDPOINT_NAME = "jumpstart-dft-llama-3-1-8b-instruct-20250302-093626"

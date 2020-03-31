#!/usr/bin/env python3

import boto3
import base64
import os
from botocore.exceptions import ClientError

def get_secret(secret_name):
    # Create a Secrets Manager client
    session = boto3.session.Session()
    client = session.client(
        service_name='secretsmanager',
        region_name=os.getenv('AWS_REGION')
    )

    try:
        get_secret_value_response = client.get_secret_value(
            SecretId=secret_name
        )
    except ClientError as e:
        if e.response['Error']['Code'] == 'DecryptionFailureException':
            # Secrets Manager can't decrypt the protected secret text using the provided KMS key.
            # Deal with the exception here, and/or rethrow at your discretion.
            raise e
        elif e.response['Error']['Code'] == 'InternalServiceErrorException':
            # An error occurred on the server side.
            # Deal with the exception here, and/or rethrow at your discretion.
            raise e
        elif e.response['Error']['Code'] == 'InvalidParameterException':
            # You provided an invalid value for a parameter.
            # Deal with the exception here, and/or rethrow at your discretion.
            raise e
        elif e.response['Error']['Code'] == 'InvalidRequestException':
            # You provided a parameter value that is not valid for the current state of the resource.
            # Deal with the exception here, and/or rethrow at your discretion.
            raise e
        elif e.response['Error']['Code'] == 'ResourceNotFoundException':
            # We can't find the resource that you asked for.
            # Deal with the exception here, and/or rethrow at your discretion.
            raise e
    else:
        # Decrypts secret using the associated KMS CMK.
        # Depending on whether the secret is a string or binary, one of these fields will be populated.
        if 'SecretString' in get_secret_value_response:
            return get_secret_value_response['SecretString']
        else:
            return base64.b64decode(get_secret_value_response['SecretBinary'])

"""
This script setup Gerrit configuration and its plugins when the container spins up.

It reads from:
 - AWS Secret Manager: Statically defined.
 - gerrit.setup: Statically defined.
 - environment variables: Dinamycally defined.

"""

GERRIT_KEY_PREFIX = "gerrit_secret_"
SSH_KEYS_DIRECTORY = "/home/gerrit/.ssh"

print("Installing SSH Keys from Secret Manager in directory: " + SSH_KEYS_DIRECTORY)

with open(SSH_KEYS_DIRECTORY + '/authorized_keys', 'w', encoding = 'utf-8') as f:
    f.write(get_secret(GERRIT_KEY_PREFIX + 'replication_user_id_rsa.pub'))
os.chmod(SSH_KEYS_DIRECTORY, 0o700)
os.chmod(SSH_KEYS_DIRECTORY + '/authorized_keys', 0o600)

print("Finished installation...")

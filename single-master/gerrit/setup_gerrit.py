#!/usr/bin/env python3

import boto3
import base64
import os
from botocore.exceptions import ClientError
from jinja2 import Environment, FileSystemLoader

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

secretIds = [
    "ssh_host_ecdsa_384_key",
    "ssh_host_ecdsa_384_key.pub",
    "ssh_host_ecdsa_521_key",
    "ssh_host_ecdsa_521_key.pub",
    "ssh_host_ecdsa_key",
    "ssh_host_ecdsa_key.pub",
    "ssh_host_ed25519_key",
    "ssh_host_ed25519_key.pub",
    "ssh_host_rsa_key",
    "ssh_host_rsa_key.pub"
]

GERRIT_KEY_PREFIX = "gerrit_secret_"
GERRIT_SSH_SECRETS_DIRECTORY = "/var/gerrit/etc/"

print("Installing SSH Keys from Secret Manager in directory: " + GERRIT_SSH_SECRETS_DIRECTORY)
for secretId in secretIds:
    print("* Installing SSH Key: " + secretId)
    with open(GERRIT_SSH_SECRETS_DIRECTORY + secretId, 'w', encoding = 'utf-8') as f:
        f.write(get_secret(GERRIT_KEY_PREFIX + secretId))

print("Setting Register Email Private Key in '" + GERRIT_SSH_SECRETS_DIRECTORY + "secure.config'")
file_loader = FileSystemLoader(GERRIT_SSH_SECRETS_DIRECTORY)
env = Environment(loader=file_loader)
template = env.get_template("secure.config.template")
with open(GERRIT_SSH_SECRETS_DIRECTORY + "secure.config", 'w', encoding = 'utf-8') as f:
    f.write(template.render(REGISTER_EMAIL_PRIVATE_KEY=get_secret(GERRIT_KEY_PREFIX + "registerEmailPrivateKey")))

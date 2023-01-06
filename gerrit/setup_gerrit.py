#!/usr/bin/env python3

import boto3
import base64
import os
from botocore.exceptions import ClientError
from jinja2 import Environment, FileSystemLoader

setupReplication = (os.getenv('SETUP_REPLICATION') == 'true')
setupHA = (os.getenv('SETUP_HA') == 'true')
setupMultiSite = (os.getenv('MULTISITE_ENABLED') == 'true')

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
            # Secrets Manager can't decrypt the protected secret text using the
            # provided KMS key.
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
            # You provided a parameter value that is not valid for the current
            # state of the resource.
            # Deal with the exception here, and/or rethrow at your discretion.
            raise e
        elif e.response['Error']['Code'] == 'ResourceNotFoundException':
            # We can't find the resource that you asked for.
            # Deal with the exception here, and/or rethrow at your discretion.
            print("Secret name '%s' was not found" % secret_name)
            raise e
    else:
        # Decrypts secret using the associated KMS CMK.
        # Depending on whether the secret is a string or binary, one of these
        # fields will be populated.
        if 'SecretString' in get_secret_value_response:
            return get_secret_value_response['SecretString']
        else:
            return base64.b64decode(get_secret_value_response['SecretBinary'])


def set_secure_password(stanza, password):
    secure_config = GERRIT_CONFIG_DIRECTORY + "secure.config"
    os.system(
        "git config -f %s %s '%s'" % (secure_config, stanza, password.strip())
    )


"""
This script setup Gerrit configuration and its plugins when the container spins up.

It reads from:
 - AWS Secret Manager: Statically defined.
 - environment variables: Dinamycally defined.

"""

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

GERRIT_KEY_PREFIX = os.getenv("GERRIT_KEY_PREFIX", "gerrit_secret")
GERRIT_CONFIG_DIRECTORY = "/var/gerrit/etc/"

print("Installing SSH Keys from Secret Manager in directory: " +
      GERRIT_CONFIG_DIRECTORY)
for secretId in secretIds:
    print("* Installing SSH Key: " + secretId)
    with open(GERRIT_CONFIG_DIRECTORY + secretId, 'w', encoding='utf-8') as f:
        f.write(get_secret(GERRIT_KEY_PREFIX + "_" + secretId))

print("Setup replication: " + str(setupReplication))

if setupReplication:
    GERRIT_SSH_DIRECTORY = "/var/gerrit/.ssh"
    GERRIT_REPLICATION_SSH_KEYS = GERRIT_SSH_DIRECTORY + "/id_rsa"

    print("Installing Replication SSH Keys from Secret Manager in: " +
          GERRIT_REPLICATION_SSH_KEYS)

    if not os.path.exists(GERRIT_SSH_DIRECTORY):
        os.mkdir(GERRIT_SSH_DIRECTORY)
        os.chmod(GERRIT_SSH_DIRECTORY, 0o700)

    with open(GERRIT_REPLICATION_SSH_KEYS, 'w', encoding='utf-8') as f:
        f.write(get_secret(GERRIT_KEY_PREFIX + '_replication_user_id_rsa'))
    os.chmod(GERRIT_REPLICATION_SSH_KEYS, 0o400)

file_loader = FileSystemLoader(GERRIT_CONFIG_DIRECTORY)
env = Environment(loader=file_loader)

set_secure_password(
    "auth.registerEmailPrivateKey",
    get_secret(GERRIT_KEY_PREFIX + "_registerEmailPrivateKey")
)
set_secure_password(
    "ldap.password",
    get_secret(GERRIT_KEY_PREFIX + "_ldapPassword")
)
set_secure_password(
    "sendemail.smtpPass",
    get_secret(GERRIT_KEY_PREFIX + "_smtpPassword")
)

BASE_CONFIG_DIR = "/tmp"
print("Setting Gerrit config in '" + GERRIT_CONFIG_DIRECTORY + "gerrit.config'")
template = env.get_template("gerrit.config.template")

config_for_template = {}
try:
    # If we don't need the monitoring stack we can avoid to set this token
    prometheus_bearer_token = get_secret(GERRIT_KEY_PREFIX + "_prometheus_bearer_token")
    config_for_template['PROMETHEUS_BEARER_TOKEN'] = prometheus_bearer_token
except ClientError as e:
    if e.response['Error']['Code'] == 'ResourceNotFoundException':
         print("[WARN] PROMETHEUS_BEARER_TOKEN not set")
    else:
        raise e

if 'HOSTED_ZONE_NAME' in os.environ:
    config_for_template['COOKIE_DOMAIN'] = os.getenv('HOSTED_ZONE_NAME')
with open(GERRIT_CONFIG_DIRECTORY + "gerrit.config", 'w',
          encoding='utf-8') as f:
    config_for_template.update({
        'LDAP_SERVER': os.getenv('LDAP_SERVER'),
        'LDAP_USERNAME': os.getenv('LDAP_USERNAME'),
        'LDAP_ACCOUNT_BASE': os.getenv('LDAP_ACCOUNT_BASE'),
        'LDAP_GROUP_BASE': os.getenv('LDAP_GROUP_BASE'),
        'LDAP_ACCOUNT_PATTERN': os.getenv('LDAP_ACCOUNT_PATTERN'),
        'SMTP_SERVER': os.getenv('SMTP_SERVER'),
        'SMTP_SERVER_PORT': os.getenv('SMTP_SERVER_PORT'),
        'SMTP_USER': os.getenv('SMTP_USER'),
        'SMTP_DOMAIN': os.getenv('SMTP_DOMAIN'),
        'SMTP_ENCRYPTION': os.getenv('SMTP_ENCRYPTION'),
        'SMTP_SSL_VERIFY': os.getenv('SMTP_SSL_VERIFY'),
        'GERRIT_HEAP_LIMIT': os.getenv('GERRIT_HEAP_LIMIT'),
        'JGIT_CACHE_SIZE': os.getenv('JGIT_CACHE_SIZE'),
        'JGIT_OPEN_FILES': os.getenv('JGIT_OPEN_FILES'),
        'GERRIT_INSTANCE_ID': os.getenv('GERRIT_INSTANCE_ID'),
        'METRICS_CLOUDWATCH_ENABLED': os.getenv('METRICS_CLOUDWATCH_ENABLED'),
        'METRICS_CLOUDWATCH_NAMESPACE': os.getenv('METRICS_CLOUDWATCH_NAMESPACE'),
        'METRICS_CLOUDWATCH_RATE': os.getenv('METRICS_CLOUDWATCH_RATE'),
        'METRICS_CLOUDWATCH_JVM_ENABLED': os.getenv('METRICS_CLOUDWATCH_JVM_ENABLED'),
        'METRICS_CLOUDWATCH_INITIAL_DELAY': os.getenv('METRICS_CLOUDWATCH_INITIAL_DELAY'),
        'METRICS_CLOUDWATCH_DRY_RUN': os.getenv('METRICS_CLOUDWATCH_DRY_RUN'),
        'METRICS_CLOUDWATCH_EXCLUDE_METRICS_LIST': os.getenv('METRICS_CLOUDWATCH_EXCLUDE_METRICS_LIST'),
        'MULTISITE_ENABLED': os.getenv('MULTISITE_ENABLED'),
        'MULTISITE_KAFKA_BROKERS': os.getenv('MULTISITE_KAFKA_BROKERS'),
        'REFS_DB_ENABLED': os.getenv('REFS_DB_ENABLED'),
        'DYNAMODB_LOCKS_TABLE_NAME': os.getenv('DYNAMODB_LOCKS_TABLE_NAME'),
        'DYNAMODB_REFS_TABLE_NAME': os.getenv('DYNAMODB_REFS_TABLE_NAME'),
        'SSHD_ADVERTISED_ADDRESS': os.getenv('SSHD_ADVERTISED_ADDRESS'),
        'XRAY_ENABLED': os.getenv('XRAY_ENABLED'),
    })
    f.write(template.render(config_for_template))

containerReplica = (os.getenv('CONTAINER_REPLICA') == 'true')


if setupReplication:
    try:
        # If we don't need the monitoring stack we can avoid to set this token
        pull_replication_bearer_token = get_secret(GERRIT_KEY_PREFIX + "_pull_replication_bearer_token")
        set_secure_password("auth.bearerToken", pull_replication_bearer_token)
    except ClientError as e:
        if e.response['Error']['Code'] == 'ResourceNotFoundException':
            print("[ERROR] PULL_REPLICATION_BEARER_TOKEN not set")
        raise e

    print("Is replica: " + str(containerReplica))
    if containerReplica:
        print("Setting replica Replication config in '" +
              GERRIT_CONFIG_DIRECTORY + "replication.config'")
        template = env.get_template("replication_replica.config.template")
        with open(GERRIT_CONFIG_DIRECTORY + "replication.config", 'w', encoding='utf-8') as f:
            REPLICA_FQDN = os.getenv('HTTP_PRIMARIES_GERRIT_SUBDOMAIN') + "." + os.getenv('HOSTED_ZONE_NAME')
            REPLICATE_ON_STARTUP = "false"
            f.write(template.render(
                    GERRIT_PRIMARY1_INSTANCE_ID=os.getenv('GERRIT_PRIMARY1_INSTANCE_ID'),
                    GERRIT_PRIMARY2_INSTANCE_ID=os.getenv('GERRIT_PRIMARY2_INSTANCE_ID', ''),
                    HTTP_PRIMARIES_LB="https://" + REPLICA_FQDN + "/${name}",
                    REPLICATE_ON_STARTUP=REPLICATE_ON_STARTUP
                    ))
    else:
        print("Setting primary Replication config in '" +
              GERRIT_CONFIG_DIRECTORY + "replication.config'")
        template = env.get_template("replication.config.template")
        with open(GERRIT_CONFIG_DIRECTORY + "replication.config", 'w', encoding='utf-8') as f:
            REPLICA_FQDN = os.getenv('REPLICA_SUBDOMAIN') + "." + os.getenv('HOSTED_ZONE_NAME')
            HTTP_REPLICA_FQDN = os.getenv('HTTP_REPLICA_SUBDOMAIN') + "." + os.getenv('HOSTED_ZONE_NAME')
            REMOTE_TARGET = os.getenv('REMOTE_REPLICATION_TARGET_HOST', '')
            # In a multi-site setup, the very first replication needs to be
            # triggered manually from site-A to site-B, once the latter is ready,
            # thus "REPLICATE_ON_STARTUP" needs to be disabled
            REPLICATE_ON_STARTUP = "false" if setupMultiSite else "true"
            f.write(template.render(
                    REPLICA_1_URL="git://" + REPLICA_FQDN + ":" + os.getenv('GIT_PORT') + "/${name}.git",
                    REPLICA_1_AMDIN_URL="ssh://gerrit@" + REPLICA_FQDN + ":" + os.getenv('GIT_SSH_PORT') + "/var/gerrit/git/${name}.git",
                    REPLICA_1_API_URL="https://" + HTTP_REPLICA_FQDN,
                    REMOTE_TARGET=REMOTE_TARGET,
                    REMOTE_TARGET_URL="git://" + REMOTE_TARGET + ":" + os.getenv('GIT_PORT') + "/${name}.git",
                    REMOTE_ADMIN_TARGET_URL="ssh://gerrit@" + REMOTE_TARGET + ":" + os.getenv('GIT_SSH_PORT') + "/var/gerrit/git/${name}.git",
                    REPLICATE_ON_STARTUP=REPLICATE_ON_STARTUP,
                    MULTISITE_GLOBAL_PROJECTS=os.getenv('MULTISITE_GLOBAL_PROJECTS', '')
                    ))

CONFIGURATION_FILE = "jgit.config"
CONFIGURATION_TARGET = GERRIT_CONFIG_DIRECTORY + CONFIGURATION_FILE
TEMPLATE_FILE = CONFIGURATION_FILE + ".template"

print("*** "+ CONFIGURATION_TARGET)
template = env.get_template(TEMPLATE_FILE)
with open(CONFIGURATION_TARGET, 'w', encoding='utf-8') as f:
    f.write(template.render(
        TRUST_FOLDER_STAT="false" if setupHA else "true"
    ))

if (setupHA):
    print("Setting HA config in '" +
          GERRIT_CONFIG_DIRECTORY + "high-availability.config'")
    template = env.get_template("high-availability.config.template")
    with open(GERRIT_CONFIG_DIRECTORY + "high-availability.config", 'w', encoding='utf-8') as f:
        f.write(template.render(
            HA_PEER_URL=os.getenv('HA_PEER_URL'),
            HA_AUTOREINDEX_POLL_INTERVAL=os.getenv('HA_AUTOREINDEX_POLL_INTERVAL'),
            MULTISITE_ENABLED=os.getenv('MULTISITE_ENABLED'),
            REFS_DB_ENABLED=os.getenv('REFS_DB_ENABLED')
        ))

if setupMultiSite:
    CONFIGURATION_TARGET = GERRIT_CONFIG_DIRECTORY + "multi-site.config"

    print("*** "+ CONFIGURATION_TARGET)
    template = env.get_template("multi-site.config.template")
    with open(CONFIGURATION_TARGET, 'w', encoding='utf-8') as f:
        f.write(template.render(
            MULTISITE_GLOBAL_PROJECTS=os.getenv('MULTISITE_GLOBAL_PROJECTS', '')
        ))

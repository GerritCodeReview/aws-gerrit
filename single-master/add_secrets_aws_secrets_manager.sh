#!/bin/bash -e

SECRETS_DIRECTORY=$1
if [ -z "$SECRETS_DIRECTORY" ];
then
  echo "Secrets directory must be specified"
  exit 1
fi

# Avoid to open output in less for each AWS command
export AWS_PAGER=;
KEY_PREFIX=gerrit_secret

echo "Adding SSH Keys..."

aws secretsmanager create-secret --name ${KEY_PREFIX}_ssh_host_ecdsa_384_key \
    --description "Gerrit ssh_host_ecdsa_384_key" \
    --secret-string file://$SECRETS_DIRECTORY/ssh_host_ecdsa_384_key
aws secretsmanager create-secret --name ${KEY_PREFIX}_ssh_host_ecdsa_384_key.pub \
    --description "Gerrit ssh_host_ecdsa_384_key.pub" \
    --secret-string file://$SECRETS_DIRECTORY/ssh_host_ecdsa_384_key.pub
aws secretsmanager create-secret --name ${KEY_PREFIX}_ssh_host_ecdsa_521_key \
    --description "Gerrit ssh_host_ecdsa_521_key" \
    --secret-string file://$SECRETS_DIRECTORY/ssh_host_ecdsa_521_key
aws secretsmanager create-secret --name ${KEY_PREFIX}_ssh_host_ecdsa_521_key.pub \
    --description "Gerrit ssh_host_ecdsa_521_key.pub" \
    --secret-string file://$SECRETS_DIRECTORY/ssh_host_ecdsa_521_key.pub
aws secretsmanager create-secret --name ${KEY_PREFIX}_ssh_host_ecdsa_key \
    --description "Gerrit ssh_host_ecdsa_key" \
    --secret-string file://$SECRETS_DIRECTORY/ssh_host_ecdsa_key
aws secretsmanager create-secret --name ${KEY_PREFIX}_ssh_host_ecdsa_key.pub \
    --description "Gerrit ssh_host_ecdsa_key.pub" \
    --secret-string file://$SECRETS_DIRECTORY/ssh_host_ecdsa_key.pub
aws secretsmanager create-secret --name ${KEY_PREFIX}_ssh_host_ed25519_key \
    --description "Gerrit ssh_host_ed25519_key" \
    --secret-string file://$SECRETS_DIRECTORY/ssh_host_ed25519_key
aws secretsmanager create-secret --name ${KEY_PREFIX}_ssh_host_ed25519_key.pub \
    --description "Gerrit ssh_host_ed25519_key.pub" \
    --secret-string file://$SECRETS_DIRECTORY/ssh_host_ed25519_key.pub
aws secretsmanager create-secret --name ${KEY_PREFIX}_ssh_host_rsa_key \
    --description "Gerrit ssh_host_rsa_key" \
    --secret-string file://$SECRETS_DIRECTORY/ssh_host_rsa_key
aws secretsmanager create-secret --name ${KEY_PREFIX}_ssh_host_rsa_key.pub \
    --description "Gerrit ssh_host_rsa_key.pub" \
    --secret-string file://$SECRETS_DIRECTORY/ssh_host_rsa_key.pub

echo "Adding Register Email Private Key..."

aws secretsmanager create-secret --name ${KEY_PREFIX}_registerEmailPrivateKey \
    --description "Gerrit Register Email Private Key" \
    --secret-string file://$SECRETS_DIRECTORY/registerEmailPrivateKey

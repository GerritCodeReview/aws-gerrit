#!/bin/bash -e

SECRETS_DIRECTORY=$1
if [ -z "$SECRETS_DIRECTORY" ];
then
  echo "Secrets directory must be specified"
  exit 1
fi

# Avoid to open output in less for each AWS command
export AWS_PAGER=;
KEY_PREFIX=${2:-gerrit_secret}

AWS_REGION=${3:-"us-east-1"}

function set-secret-string {
  SECRET_ID=$1

  if aws secretsmanager describe-secret --region ${AWS_REGION} --secret-id ${KEY_PREFIX}_${SECRET_ID} > /dev/null 2>&1
  then
    echo "Updating secret ${KEY_PREFIX}_${SECRET_ID} ..."
    aws secretsmanager put-secret-value --region ${AWS_REGION} \
      --secret-id ${KEY_PREFIX}_${SECRET_ID} \
      --secret-string file://$SECRETS_DIRECTORY/${SECRET_ID}
  else
    echo "Creating secret ${KEY_PREFIX}_${SECRET_ID} ..."
    aws secretsmanager create-secret --region ${AWS_REGION} \
      --name ${KEY_PREFIX}_${SECRET_ID} \
      --description "Gerrit ${SECRET_ID}" \
      --secret-string file://$SECRETS_DIRECTORY/${SECRET_ID}
  fi
}

echo "Adding SSH Keys..."

keys=(
  "ssh_host_ecdsa_384_key"
  "ssh_host_ecdsa_384_key.pub"
  "ssh_host_ecdsa_521_key"
  "ssh_host_ecdsa_521_key.pub"
  "ssh_host_ecdsa_key"
  "ssh_host_ecdsa_key.pub"
  "ssh_host_ed25519_key"
  "ssh_host_ed25519_key.pub"
  "ssh_host_rsa_key"
  "ssh_host_rsa_key.pub"
)

for key_name in "${keys[@]}"
do
  set-secret-string ${key_name}
done

if [ -f "$SECRETS_DIRECTORY/replication_user_id_rsa.pub" ]; then
  echo "Adding Replication SSH Keys..."
  set-secret-string replication_user_id_rsa.pub
  set-secret-string replication_user_id_rsa
fi

echo "Adding Register Email Private Key..."
set-secret-string registerEmailPrivateKey

echo "Adding LDAP password..."
set-secret-string ldapPassword

echo "Adding SMTP password..."
set-secret-string smtpPassword

if [ -f "$SECRETS_DIRECTORY/prometheus_bearer_token" ]; then
  echo "Adding Prometheus bearer token..."
  set-secret-string prometheus_bearer_token
fi

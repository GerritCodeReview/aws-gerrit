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
  echo aws secretsmanager create-secret --name ${KEY_PREFIX}_${key_name} \
      --description "Gerrit ${key_name}" \
      --secret-string file://$SECRETS_DIRECTORY/${key_name}
done

if [ -f "$SECRETS_DIRECTORY/replication_user_id_rsa.pub" ]; then
  echo "Adding Replication SSH Keys..."
  aws secretsmanager create-secret --name ${KEY_PREFIX}_replication_user_id_rsa.pub \
      --description "Gerrit replication_user_id_rsa.pub" \
      --secret-string file://$SECRETS_DIRECTORY/replication_user_id_rsa.pub
  aws secretsmanager create-secret --name ${KEY_PREFIX}_replication_user_id_rsa \
      --description "Gerrit replication_user_id_rsa" \
      --secret-string file://$SECRETS_DIRECTORY/replication_user_id_rsa
fi

echo "Adding Register Email Private Key..."

aws secretsmanager create-secret --name ${KEY_PREFIX}_registerEmailPrivateKey \
    --description "Gerrit Register Email Private Key" \
    --secret-string file://$SECRETS_DIRECTORY/registerEmailPrivateKey

echo "Adding LDAP password..."

aws secretsmanager create-secret --name ${KEY_PREFIX}_ldapPassword \
    --description "LDAP password" \
    --secret-string file://$SECRETS_DIRECTORY/ldapPassword

echo "Adding SMTP password..."

aws secretsmanager create-secret --name ${KEY_PREFIX}_smtpPassword \
    --description "SMTP password" \
    --secret-string file://$SECRETS_DIRECTORY/smtpPassword

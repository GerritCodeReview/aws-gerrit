#!/bin/bash -e

PROMETHEUS_BEARER_TOKEN=$1
if [ -z "$PROMETHEUS_BEARER_TOKEN" ];
then
  echo "Prometheus Bear Token must be specified"
  exit 1
fi

# Avoid to open output in less for each AWS command
export AWS_PAGER=;
KEY_PREFIX=gerrit_secret

echo "Adding Prometheus Bearer Token..."

aws secretsmanager create-secret --name ${KEY_PREFIX}_prometheus_bearer_token \
    --description "Prometheus Bearer Token" \
    --secret-string ${PROMETHEUS_BEARER_TOKEN}

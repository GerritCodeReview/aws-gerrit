#!/bin/bash -e

/tmp/setup_gerrit.py
git config -f /var/gerrit/etc/gerrit.config gerrit.canonicalWebUrl "${CANONICAL_WEB_URL:-http://$HOSTNAME}"
git config -f /var/gerrit/etc/gerrit.config httpd.listenUrl "${HTTPD_LISTEN_URL:-http://*:8080/}"
git config -f /var/gerrit/etc/gerrit.config container.slave "${CONTAINER_SLAVE:-false}"

if [ $CONTAINER_SLAVE ]; then
  echo "Slave mode..."
  retry_count=0
  MAX_RETRIES=10
  while [ ! -d /var/gerrit/git/All-Projects.git ]
  do
    retry_count=$((retry_count+1))
    if [ "$retry_count" -ge "$MAX_RETRIES" ]; then
        exit 1
    fi
    echo "Sleep before checking replication happened ($retry_count/$MAX_RETRIES)..."
    sleep 60
  done
  rm -fr /var/gerrit/plugins/replication.jar
  java -jar /var/gerrit/bin/gerrit.war reindex --index groups
else
  echo "Master mode (init phase)..."
  java -jar /var/gerrit/bin/gerrit.war init --no-auto-start --batch --install-all-plugins -d /var/gerrit
  if [ $REINDEX_AT_STARTUP == "true" ]; then
    echo "Master mode (reindex phase)..."
    java -jar /var/gerrit/bin/gerrit.war reindex -d /var/gerrit
  fi
fi

echo "Running Gerrit ..."
exec /var/gerrit/bin/gerrit.sh run

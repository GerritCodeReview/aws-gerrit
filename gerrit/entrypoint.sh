#!/bin/bash -e

/tmp/setup_gerrit.py
git config -f /var/gerrit/etc/gerrit.config gerrit.canonicalWebUrl "${CANONICAL_WEB_URL:-http://$HOSTNAME}"
git config -f /var/gerrit/etc/gerrit.config httpd.listenUrl "${HTTPD_LISTEN_URL:-http://*:8080/}"
git config -f /var/gerrit/etc/gerrit.config container.slave "${CONTAINER_SLAVE:-false}"

if [ ! -d /var/gerrit/git/All-Projects.git ] || [ "$1" == "init" ]
then
  echo "Initializing Gerrit site ..."
  java -jar /var/gerrit/bin/gerrit.war init --no-auto-start --batch --install-all-plugins -d /var/gerrit
  if [ $CONTAINER_SLAVE ]
  then
    echo "Cleanup slave git directory"
    rm -f /var/gerrit/plugins/replication.jar
    rm -fr /var/gerrit/git/*
  fi
fi

if [ $CONTAINER_SLAVE ]
then
  echo "Waiting 5 minutes for replication from master to happen before starting slave"
  sleep 300
  java -jar /var/gerrit/bin/gerrit.war reindex --index groups
fi

echo "Running Gerrit ..."
exec /var/gerrit/bin/gerrit.sh run

#!/bin/bash -e

if [ ! -d /var/gerrit/git/All-Projects.git ] || [ "$1" == "init" ]
then
  rm -fr /var/gerrit/plugins/*
  echo "Initializing Gerrit site ..."
  java -jar /var/gerrit/bin/gerrit.war init --batch --install-all-plugins -d /var/gerrit
  java -jar /var/gerrit/bin/gerrit.war reindex -d /var/gerrit
fi

if [ $CONTAINER_SLAVE ]
then
  echo "Cleanup slave git directory"
  rm -fr /var/gerrit/git/*
  echo "Waiting 3 minutes for replication from master to happen before starting slave"
  sleep 180
else
  echo "Master instance, no need to sleep"
fi

if [ "$1" != "init" ]
then
  /tmp/setup_gerrit.py

  git config -f /var/gerrit/etc/gerrit.config gerrit.canonicalWebUrl "${CANONICAL_WEB_URL:-http://$HOSTNAME}"
  git config -f /var/gerrit/etc/gerrit.config httpd.listenUrl "${HTTPD_LISTEN_URL:-http://*:8080/}"
  git config -f /var/gerrit/etc/gerrit.config container.slave "${CONTAINER_SLAVE:-false}"

  echo "Running Gerrit ..."
  exec /var/gerrit/bin/gerrit.sh run
fi

#!/bin/bash -e

/tmp/setup_gerrit.py
git config -f /var/gerrit/etc/gerrit.config gerrit.canonicalWebUrl "${CANONICAL_WEB_URL:-http://$HOSTNAME}"
git config -f /var/gerrit/etc/gerrit.config httpd.listenUrl "${HTTPD_LISTEN_URL:-http://*:8080/}"

if [ ! -d /var/gerrit/git/All-Projects.git ] || [ "$1" == "init" ]
then
  rm -fr /var/gerrit/plugins/*
  echo "Initializing Gerrit site ..."
  java -jar /var/gerrit/bin/gerrit.war init --batch --no-auto-start --install-all-plugins -d /var/gerrit
fi

echo "Running Gerrit ..."
exec /var/gerrit/bin/gerrit.sh run

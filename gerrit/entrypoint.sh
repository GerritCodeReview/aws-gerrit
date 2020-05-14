#!/bin/bash -e

/tmp/setup_gerrit.py
git config -f /var/gerrit/etc/gerrit.config gerrit.canonicalWebUrl "${CANONICAL_WEB_URL:-http://$HOSTNAME}"
git config -f /var/gerrit/etc/gerrit.config httpd.listenUrl "${HTTPD_LISTEN_URL:-http://*:8080/}"
git config -f /var/gerrit/etc/gerrit.config container.slave "${CONTAINER_SLAVE:-false}"





if [ $CONTAINER_SLAVE ]; then
  rm -fr /var/gerrit/plugins/replication.jar
  java -jar /var/gerrit/bin/gerrit.war reindex --index groups
elif [ -d /var/gerrit/git/All-Projects.git ]; then
  java -jar /var/gerrit/bin/gerrit.war reindex -d /var/gerrit
else
  java -jar /var/gerrit/bin/gerrit.war init --no-auto-start --batch --install-all-plugins -d /var/gerrit
fi

echo "Running Gerrit ..."
exec /var/gerrit/bin/gerrit.sh run

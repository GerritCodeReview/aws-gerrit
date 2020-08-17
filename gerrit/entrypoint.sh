#!/bin/bash -e

/tmp/setup_gerrit.py
git config -f /var/gerrit/etc/gerrit.config gerrit.canonicalWebUrl "${CANONICAL_WEB_URL:-http://$HOSTNAME}"
git config -f /var/gerrit/etc/gerrit.config httpd.listenUrl "${HTTPD_LISTEN_URL:-http://*:8080/}"
git config -f /var/gerrit/etc/gerrit.config container.slave "${CONTAINER_SLAVE:-false}"

if [ $CONTAINER_SLAVE ]; then
  echo "Slave mode..."

  echo "Ensure master specific plugins and libraries are not installed:"
  for jar in "lib/multi-site.jar" "plugins/multi-site.jar" "lib/replication.jar" \
    "lib/events-broker.jar" "plugins/kafka-events.jar" "plugins/zookeeper-refdb.jar" \
    "plugins/websession-broker.jar" "plugins/high-availability.jar"
  do
    echo "rm -f /var/gerrit/$jar"
    rm -f /var/gerrit/"$jar"
  done

  if [ ! -d /var/gerrit/git/All-Projects.git ] ||
     [ ! -d /var/gerrit/git/All-Users.git ] ||
     [ `git --git-dir=/var/gerrit/git/All-Projects.git show-ref | wc -l` -eq 0 ] ||
     [ `git --git-dir=/var/gerrit/git/All-Users.git show-ref | wc -l` -eq 0 ]; then
     echo "Init phase..."
     java -jar /var/gerrit/bin/gerrit.war init --no-auto-start --batch --install-all-plugins -d /var/gerrit
  else
    echo "Reindexing phase..."
    java -jar /var/gerrit/bin/gerrit.war reindex --index groups
  fi
  rm -fr /var/gerrit/plugins/replication.jar

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

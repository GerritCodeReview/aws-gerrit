#!/bin/bash -e

/tmp/setup_gerrit.py
git config -f /var/gerrit/etc/gerrit.config gerrit.canonicalWebUrl "${CANONICAL_WEB_URL:-http://$HOSTNAME}"
git config -f /var/gerrit/etc/gerrit.config httpd.listenUrl "${HTTPD_LISTEN_URL:-http://*:8080/}"
git config -f /var/gerrit/etc/gerrit.config container.slave "${CONTAINER_SLAVE:-false}"

if [ $CONTAINER_SLAVE ]; then
  echo "Slave mode..."

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
  # if [ $REINDEX_AT_STARTUP == "true" ]; then
    cd /var/gerrit/git
    if [ ! -d /var/gerrit/git/linux.git ]; then
      #git clone --mirror "https://gerrit.googlesource.com/gerrit"
      git clone --mirror https://github.com/torvalds/linux.git
    fi
    echo "Master mode (reindex phase)..."
    java -jar /var/gerrit/bin/gerrit.war reindex -d /var/gerrit
  # fi
fi

echo "Running Gerrit ..."
exec /var/gerrit/bin/gerrit.sh run

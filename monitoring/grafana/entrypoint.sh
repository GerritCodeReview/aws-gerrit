#!/bin/bash -e

echo "Updating Grafana 'server.domain' to $GRAFANA_DOMAIN..."
sed -i -e "s|{{DOMAIN}}|$GRAFANA_DOMAIN|g" /etc/grafana/config.ini

/run.sh

#!/bin/bash -e

echo "Updating Grafana 'server.domain' to $GRAFANA_DOMAIN..."
sed -i -e "s|{{DOMAIN}}|$GRAFANA_DOMAIN|g" /etc/grafana/config.ini
sed -i -e "s|{{PROMETHEUS_URL}}|$PROMETHEUS_URL|g" /etc/grafana/provisioning/datasources/prometheus.yml


/run.sh

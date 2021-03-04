#!/bin/bash -e

echo "Updating Grafana templates..."
sed -i -e "s|{{DOMAIN}}|$GRAFANA_DOMAIN|g" /etc/grafana/config.ini
sed -i -e "s|{{PROMETHEUS_URL}}|$PROMETHEUS_URL|g" /etc/grafana/provisioning/datasources/prometheus.yml
sed -i -e "s|{{PRIMARY_URL}}|$PRIMARY_URL|g" /var/lib/grafana/dashboards/Gerrit.json
sed -i -e "s|{{REPLICA_URL}}|$REPLICA_URL|g" /var/lib/grafana/dashboards/Gerrit.json

/run.sh

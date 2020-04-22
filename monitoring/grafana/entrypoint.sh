#!/bin/bash -e

echo "Updating Grafana templates..."
sed -i -e "s|{{DOMAIN}}|$GRAFANA_DOMAIN|g" /etc/grafana/config.ini
sed -i -e "s|{{PROMETHEUS_URL}}|$PROMETHEUS_URL|g" /etc/grafana/provisioning/datasources/prometheus.yml
sed -i -e "s|{{MASTER_URL}}|$MASTER_URL|g" /var/lib/grafana/dashboards/Gerrit.json
sed -i -e "s|{{SLAVE_URL}}|$SLAVE_URL|g" /var/lib/grafana/dashboards/Gerrit.json

/run.sh

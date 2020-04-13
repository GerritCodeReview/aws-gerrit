#!/bin/bash -e

sed -i -e "s|PROMETHEUS_BEARER_TOKEN|$PROMETHEUS_BEARER_TOKEN|g" /etc/prometheus/prometheus.yml

/bin/prometheus --config.file=/etc/prometheus/prometheus.yml --storage.tsdb.path=/prometheus --web.console.libraries=/usr/share/prometheus/console_libraries --web.console.templates=/usr/share/prometheus/consoles

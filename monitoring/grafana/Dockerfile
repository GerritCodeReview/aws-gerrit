FROM grafana/grafana:6.7.0

USER root
ADD ./provisioning /etc/grafana/provisioning
ADD ./config.ini /etc/grafana/config.ini
ADD ./dashboards /var/lib/grafana/dashboards
COPY entrypoint.sh /entrypoint.sh

RUN chown -R grafana:grafana /etc/grafana && \
    chown -R grafana:grafana /var/lib/grafana && \
    chown grafana:grafana /entrypoint.sh && \
    chmod +x /entrypoint.sh

USER grafana
ENTRYPOINT /entrypoint.sh

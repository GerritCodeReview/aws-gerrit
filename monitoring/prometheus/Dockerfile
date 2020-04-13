FROM prom/prometheus
ADD prometheus.yml /etc/prometheus/
COPY --chown=root:root entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/bin/env"]
CMD ["sh","/entrypoint.sh"]

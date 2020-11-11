FROM prom/prometheus
ADD prometheus.yml /etc/prometheus/
COPY entrypoint.sh /entrypoint.sh
RUN chown root:root /entrypoint.sh
ENTRYPOINT ["/bin/env"]
CMD ["sh","/entrypoint.sh"]

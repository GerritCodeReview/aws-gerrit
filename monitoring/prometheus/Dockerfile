FROM prom/prometheus
ADD prometheus.yml /etc/prometheus/
COPY --chown=root:root entrypoint.sh /entrypoint.sh
COPY --chown=gerrit:gerrit setup_gerrit.py /tmp
RUN chmod +x /tmp/setup_gerrit.py \
    && pip3 install -r /tmp/requirements.txt
ENTRYPOINT ["/bin/env"]
CMD ["sh","/entrypoint.sh"]

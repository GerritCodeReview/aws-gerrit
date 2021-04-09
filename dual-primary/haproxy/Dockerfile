FROM haproxy:1.7.14

RUN apt-get update && \
    apt-get -y install gettext-base netcat && \
    mkdir /var/lib/haproxy && \
    mkdir /var/run/haproxy && \
    chown haproxy: /var/lib/haproxy /var/run/haproxy

COPY haproxy.cfg.template /usr/local/etc/haproxy/

COPY docker-entrypoint.sh /usr/local/bin/

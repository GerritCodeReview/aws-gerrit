FROM haproxy:1.7

RUN apt-get update && \
    apt-get -y install gettext-base netcat && \
    mkdir /var/lib/haproxy && \
    mkdir /var/run/haproxy && \
    useradd haproxy && \
    chown haproxy: /var/lib/haproxy /var/run/haproxy

COPY haproxy.cfg.template /usr/local/etc/haproxy/
COPY haproxy.cfg.multisite.template /usr/local/etc/haproxy/

COPY docker-entrypoint.sh /

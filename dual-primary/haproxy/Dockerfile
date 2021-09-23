FROM haproxy:1.9.8

RUN useradd -r haproxy

RUN apt-get update && \
    apt-get -y install gettext-base netcat procps telnet && \
    mkdir /var/lib/haproxy && \
    mkdir /var/run/haproxy && \
    chown haproxy: /var/lib/haproxy /var/run/haproxy

COPY haproxy.cfg.template /usr/local/etc/haproxy/

COPY docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

FROM haproxy:1.7

RUN mkdir /var/lib/haproxy && \
    mkdir /var/run/haproxy && \
    useradd haproxy && \
    chown haproxy: /var/lib/haproxy /var/run/haproxy

COPY haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg

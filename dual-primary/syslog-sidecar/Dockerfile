FROM ubuntu:bionic

EXPOSE 514/udp

WORKDIR /app
RUN apt update && apt install -y wget
RUN wget https://s3.dualstack.us-east-2.amazonaws.com/aws-xray-assets.us-east-2/xray-daemon/aws-xray-daemon-3.x.deb
RUN dpkg -i aws-xray-daemon-3.x.deb

COPY 49-haproxy.conf /etc/rsyslog.d/
COPY init.sh .
RUN chmod +x ./init.sh

ENTRYPOINT /bin/bash -c ./init.sh
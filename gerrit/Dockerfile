ARG GERRIT_VERSION
ARG GERRIT_PATCH
FROM gerritcodereview/gerrit:$GERRIT_VERSION.$GERRIT_PATCH-almalinux8

ARG withXRay=false

USER root

RUN  yum install -y python36 python3-libs python36-devel python3-pip unzip wget

COPY ssh-config /var/gerrit/.ssh/config
RUN chown -R gerrit:gerrit /var/gerrit/.ssh

# Installing scripts to get SSH Keys from Secret Manager
COPY requirements.txt /tmp
RUN chown gerrit:gerrit /tmp/requirements.txt

COPY setup_gerrit.py /tmp
RUN chown gerrit:gerrit /tmp/setup_gerrit.py

RUN chmod +x /tmp/setup_gerrit.py \
    && pip3 install --require-hashes --upgrade -r /tmp/requirements.txt

COPY plugins /var/gerrit/plugins
COPY lib /var/gerrit/lib
COPY etc /var/gerrit/etc

RUN if [ "$withXRay" = "true" ]; then \
    echo "Building docker with xray-agent" && \
    wget -P /tmp/ https://github.com/aws/aws-xray-java-agent/releases/latest/download/xray-agent.zip && \
    unzip /tmp/xray-agent.zip -d /tmp; \
  fi

RUN chown -R gerrit:gerrit \
    /var/gerrit/plugins \
    /var/gerrit/lib \
    /var/gerrit/etc

USER gerrit

ARG GERRIT_WAR_URL
RUN bash -c '[ "$GERRIT_WAR_URL" == "" ] || curl $GERRIT_WAR_URL > /var/gerrit/bin/gerrit.war'

ENV PATH ${PATH}:/var/gerrit/.local/bin

WORKDIR /var/gerrit

COPY ./entrypoint.sh /bin

ENTRYPOINT /bin/entrypoint.sh

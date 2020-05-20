FROM gerritcodereview/gerrit:$GERRIT_VERSION.$GERRIT_PATCH-centos8

USER root

RUN  yum install -y python36 python3-libs python36-devel python3-pip

COPY --chown=gerrit:gerrit ssh-config /var/gerrit/.ssh/config

# Installing scripts to get SSH Keys from Secret Manager
COPY --chown=gerrit:gerrit requirements.txt /tmp
COPY --chown=gerrit:gerrit gerrit.setup /tmp
COPY --chown=gerrit:gerrit replication.setup /tmp
COPY --chown=gerrit:gerrit setup_gerrit.py /tmp
RUN chmod +x /tmp/setup_gerrit.py \
    && pip3 install -r /tmp/requirements.txt

USER gerrit

COPY --chown=gerrit:gerrit plugins /var/gerrit/plugins
COPY --chown=gerrit:gerrit etc /var/gerrit/etc

# Install AWS cli
RUN pip3 install awscli --upgrade --user
ENV PATH ${PATH}:/var/gerrit/.local/bin

WORKDIR /var/gerrit

COPY ./entrypoint.sh /bin

ENTRYPOINT /bin/entrypoint.sh

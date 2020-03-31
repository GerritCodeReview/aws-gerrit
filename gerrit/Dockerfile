FROM gerritcodereview/gerrit:latest

USER root

RUN yum install -y https://centos7.iuscommunity.org/ius-release.rpm \
    && yum update -y \
    && yum install -y python36u python36u-libs python36u-devel python36u-pip

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

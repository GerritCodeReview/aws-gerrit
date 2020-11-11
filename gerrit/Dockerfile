FROM gerritcodereview/gerrit:$GERRIT_VERSION.$GERRIT_PATCH-centos8

USER root

RUN  yum install -y python36 python3-libs python36-devel python3-pip

COPY ssh-config /var/gerrit/.ssh/config
RUN chown gerrit:gerrit /var/gerrit/.ssh/config

# Installing scripts to get SSH Keys from Secret Manager
COPY requirements.txt /tmp
RUN chown gerrit:gerrit /tmp/requirements.txt

COPY setup_gerrit.py /tmp
RUN chown gerrit:gerrit /tmp/setup_gerrit.py

RUN chmod +x /tmp/setup_gerrit.py \
    && pip3 install -r /tmp/requirements.txt

USER gerrit

COPY plugins /var/gerrit/plugins
RUN chown -R gerrit:gerrit /var/gerrit/plugins

COPY lib /var/gerrit/lib
RUN chown -R gerrit:gerrit /var/gerrit/lib

COPY etc /var/gerrit/etc
RUN chown -R gerrit:gerrit /var/gerrit/etc

# Install AWS cli
RUN pip3 install awscli --upgrade --user
ENV PATH ${PATH}:/var/gerrit/.local/bin

WORKDIR /var/gerrit

COPY ./entrypoint.sh /bin

ENTRYPOINT /bin/entrypoint.sh

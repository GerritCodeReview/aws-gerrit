FROM gerritcodereview/gerrit:$GERRIT_VERSION.$GERRIT_PATCH-centos8

USER root

RUN  yum install -y python36 python3-libs python36-devel python3-pip

COPY ssh-config /var/gerrit/.ssh/config
RUN chown -R gerrit:gerrit /var/gerrit/.ssh

# Installing scripts to get SSH Keys from Secret Manager
COPY requirements.txt /tmp
RUN chown gerrit:gerrit /tmp/requirements.txt

COPY setup_gerrit.py /tmp
RUN chown gerrit:gerrit /tmp/setup_gerrit.py

RUN chmod +x /tmp/setup_gerrit.py \
    && pip3 install -r /tmp/requirements.txt

COPY plugins /var/gerrit/plugins
COPY lib /var/gerrit/lib
COPY etc /var/gerrit/etc

RUN chown -R gerrit:gerrit \
    /var/gerrit/plugins \
    /var/gerrit/lib \
    /var/gerrit/etc

USER gerrit

RUN bash -c '[ "$GERRIT_WAR_URL" == "" ] || curl $GERRIT_WAR_URL > /var/gerrit/bin/gerrit.war'

# Install AWS cli
RUN pip3 install awscli --upgrade --user
ENV PATH ${PATH}:/var/gerrit/.local/bin

WORKDIR /var/gerrit

COPY ./entrypoint.sh /bin

ENTRYPOINT /bin/entrypoint.sh

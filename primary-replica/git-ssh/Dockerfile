FROM panubo/sshd:1.2.0

RUN apk add git

# This hack is widely applied to avoid python printing issues in docker containers.
# See: https://github.com/Docker-Hub-frolvlad/docker-alpine-python3/pull/13
ENV PYTHONUNBUFFERED=1

RUN echo "**** install Python ****" && \
    apk add --no-cache python3 && \
    if [ ! -e /usr/bin/python ]; then ln -sf python3 /usr/bin/python ; fi && \
    \
    echo "**** install pip ****" && \
    python3 -m ensurepip && \
    rm -r /usr/lib/python*/ensurepip && \
    if [ ! -e /usr/bin/pip ]; then ln -s pip3 /usr/bin/pip ; fi

RUN adduser --h /home/gerrit -D gerrit && \
    mkdir -p /home/gerrit/.ssh && \
    chown -R gerrit:gerrit /home/gerrit/.ssh
COPY requirements.txt /tmp
RUN chown gerrit:gerrit /tmp/requirements.txt

COPY setup_ssh.py /tmp
RUN chown gerrit:gerrit /tmp/setup_ssh.py

RUN chmod +x /tmp/setup_ssh.py \
    && pip3 install --require-hashes --upgrade -r /tmp/requirements.txt

COPY ./entrypoint.sh /bin

CMD /bin/entrypoint.sh

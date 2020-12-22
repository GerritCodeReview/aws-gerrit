FROM lpicanco/java11-alpine:latest

MAINTAINER Antonio Barone <tony@gerritforge.com>

ARG JGIT_VERSION=5.10.0.202012080955

COPY scripts/* /usr/bin/scripts/

RUN apk add --update curl bash git findutils \
      && curl -o /bin/jgit https://repo.eclipse.org/content/groups/releases//org/eclipse/jgit/org.eclipse.jgit.pgm/${JGIT_VERSION}-r/org.eclipse.jgit.pgm-${JGIT_VERSION}-r.sh \
      && chmod -R +x /bin/jgit /usr/bin/scripts \
      && rm -rf /var/cache/apk/*

VOLUME /git
WORKDIR /usr/bin/scripts

ENTRYPOINT [ "/usr/bin/scripts/gc.sh" ]
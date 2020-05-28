FROM alpine:3.11

RUN apk add git git-daemon

RUN adduser --disabled-password gerrit

USER gerrit

ENTRYPOINT git daemon --enable=receive-pack --reuseaddr --verbose \
                      --export-all --port=9418 --listen=0.0.0.0 \
                      --base-path=/var/gerrit/git /var/gerrit/git

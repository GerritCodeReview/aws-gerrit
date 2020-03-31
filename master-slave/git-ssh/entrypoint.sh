#!/bin/bash -e

/tmp/setup_ssh.py
chown -R gerrit:gerrit /home/gerrit/.ssh

/usr/sbin/sshd -D -e -f /etc/ssh/sshd_config

# echo "Ready to start: $@"
#
# exec "$@"

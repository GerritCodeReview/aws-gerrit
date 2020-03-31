#!/bin/bash -e

/tmp/setup_ssh.py
chown -R gerrit:gerrit /home/gerrit/.ssh

chown -R gerrit:gerrit /var/gerrit/git/

sed -i s/"gerrit:!"/"gerrit:*"/g /etc/shadow

/usr/sbin/sshd -D -e -f /etc/ssh/sshd_config

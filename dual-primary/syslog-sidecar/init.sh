#!/bin/bash

apt update
apt install -y rsyslog
service rsyslog start
/usr/bin/xray
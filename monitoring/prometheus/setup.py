#!/usr/bin/env python3

import boto3
import base64
import os
import configparser
from botocore.exceptions import ClientError
from jinja2 import Environment, FileSystemLoader

env = Environment(loader=file_loader)

config_for_template = {}

config_for_template['PROMETHEUS_BEARER_TOKEN'] = os.getenv('PROMETHEUS_BEARER_TOKEN')

if 'SLAVE_URL' in os.environ && len(os.getenv('SLAVE_URL')):
    config_for_template['SLAVE_URL'] = os.getenv('SLAVE_URL')

if 'MASTER_1_URL' in os.environ && len(os.getenv('MASTER_1_URL')):
    config_for_template['MASTER_1_URL'] = os.getenv('MASTER_1_URL')

if 'MASTER_2_URL' in os.environ && len(os.getenv('MASTER_2_URL')):
    config_for_template['MASTER_2_URL'] = os.getenv('MASTER_2_URL')

with open('/etc/prometheus/prometheus.yml', 'w',
          encoding='utf-8') as f:
    f.write(template.render(config_for_template))

#!/usr/bin/env python3

import boto3
import base64
import os
import configparser
from botocore.exceptions import ClientError
from jinja2 import Environment, FileSystemLoader

env = Environment(loader=file_loader)

config_for_template = {}

if 'SLAVE_URL' in os.environ:
    config_for_template['SLAVE_URL'] = os.getenv('SLAVE_URL')

if 'MASTER_1_URL' in os.environ:
    config_for_template['MASTER_1_URL'] = os.getenv('MASTER_1_URL')

if 'MASTER_2_URL' in os.environ:
    config_for_template['MASTER_2_URL'] = os.getenv('MASTER_2_URL')

with open(GERRIT_CONFIG_DIRECTORY + "gerrit.config", 'w',
          encoding='utf-8') as f:
    f.write(template.render(config_for_template))

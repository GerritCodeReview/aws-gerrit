## Gerrit AWS Templates
This repository holds a collection of [AWS CloudFormation](https://aws.amazon.com/cloudformation/)
templates and scripts to deploy Gerrit in AWS.

## Outline

- [Overview](#overview)
- [Pre-requisites](#pre-requisites)
- [Templates](#templates)
- [External Services](#external-services)

## Overview

The goal is to provide guidelines, examples as well as out-of-the-box templates and scripts to deploy fully-functional
Gerrit setups in AWS.

With Gerrit AWS Templates, developers and administrator can create a production-ready
installation on the cloud in minutes and in a repeatable way, allowing them
to focus on fine tuning of the Gerrit configuration to suit the user needs.

The provided CloudFormation templates automate the entire creation and deployment
of the infrastructure and the application.

## Pre-requisites

To manage your AWS services via command line you will need to install
[AWS CLI](https://aws.amazon.com/cli/) and set it up to point to your account.

To build gerrit and related-components' images
[Docker](https://www.docker.com/)

## Templates

* [Standalone Gerrit master sandbox with LDAP authentication](/single-master/README.md)
* [Gerrit master and slave sandbox with LDAP authentication](/master-slave/README.md)
* [Gerrit dual-master in HA sandbox with LDAP authentication](/dual-master/README.md)

## External services

This is a list of external services that you might need to setup your stack and some suggestions
on how to easily create them.

#### SMTP Server

If you need to setup a SMTP service Amazon Simple Email Service can be used.
Details how setup Amazon SES can be found [here](https://docs.aws.amazon.com/ses/latest/DeveloperGuide/send-email-set-up.html).

To correctly setup email notifications Gerrit requires ssl protocol on default port 465 to
be enabled on SMTP Server. It is possible to setup Gerrit to talk to standard SMTP port 25
but by default all EC2 instances are blocking it. To enable port 25 please follow [this](https://aws.amazon.com/premiumsupport/knowledge-center/ec2-port-25-throttle/) link.

#### LDAP Server

If you need a testing LDAP server you can find details on how to easily
create one in the [LDAP folder](ldap/README.md).

#### Monitoring

If you want to monitor your system, you can add a Prometheus and Grafana stack.
[Here](monitoring/README.md) you can find the details on how to add it.

## TODO

### Ensure ECR repositories

ECR's Repositories existence should be ensured programmatically rather than a manual step

### Rollout strategy

Allow to upgrade and existing stack without requiring to tear it down first

### Roles and permissions

Overall roles and permissions are too open. Proper security groups should be enabled to ensure only
the minimum required access to resources.

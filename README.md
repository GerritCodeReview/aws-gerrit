## Gerrit AWS Templates
Those are a collection of [AWS CloudFormation](https://aws.amazon.com/cloudformation/)
templates and scripts to deploy Gerrit in AWS.

The aim is to provide some guidelines and example on how to deploy different Gerrit
setups in the Cloud using AWS as provider.

## Outline

- [Overview](#overview)
- [Pre-requisites](#pre-requisites)
- [Templates](#templates)
- [External Services](#external-services)

## Overview

The goal of Gerrit AWS Templates is to provide fully-functional Gerrit installations
to helps users deploying Gerrit on AWS by providing out-of-the-box templates.

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

To manipulate aws cloudformation outputs
[jq](https://stedolan.github.io/jq/)

## Templates

* [Standalone Gerrit primary sandbox with LDAP authentication](/single-primary/README.md)
* [Gerrit primary and replica sandbox with LDAP authentication](/primary-replica/README.md)
* [Gerrit dual-primary in HA sandbox with LDAP authentication](/dual-primary/README.md)

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

### Operations

A set of utilities to perform operational tasks is also provided.
Refer to the relevant [documentation](./operations/Operations.md) for details on this.
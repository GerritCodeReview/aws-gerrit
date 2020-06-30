## Gerrit AWS Templates
This repository holds a collection of [AWS CloudFormation](https://aws.amazon.com/cloudformation/)
templates and scripts to deploy Gerrit in AWS.

## Outline

- [Overview](#overview)
- [Pre-requisites](#pre-requisites)
- [Templates](#templates)

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

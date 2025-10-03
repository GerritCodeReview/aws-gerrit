# DEPRECATION NOTICE

GerritForge has decided to [change the license to BSL](https://gitenterprise.me/2025/09/30/re-licensing-gerritforge-plugins-welcome-to-gerrit-enterprise/)
therefore the Apache 2.0 version of this plugin is deprecated.
The recommended version of the aws-gerrit plugin is on [GitHub](https://github.com/GerritForge/aws-gerrit)
and the development continues on [GerritHub.io](https://review.gerrithub.io/admin/repos/GerritForge/aws-gerrit,general).

## Gerrit AWS Templates (DEPRECATED)
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

## Logging

All recipes stream every log to CloudWatch. This always includes `sshd_log`,
`httpd_log` and `gc_log`.

## Resource names

When possible AWS resources are explicitly named so that they can be easily
distinguished when querying them via the aws-cli, or the AWS UI console, so that
their intent is clear.

However, AWS requires that resource names be no longer than 32 characters. For
this reason we adopt a naming-convention that trades off a bit of clarity in
favour of a more economical usage of characters.

* R - Replica
* P - Primary
* H - HTTP protocol
* S - SSH protocol
* G - GIT protocol

Some examples:

* In the `Load Balancers` section:
    - `production-P-H` stands
      for `Load Balancer serving HTTP traffic to the Primary Gerrit`
    - `production-R-S` stands
      for `Load Balancer serving SSH traffic to the Gerrit Replica`
    - `production-Ps-H` stands
      for `Load Balancer serving SSH traffic to both Gerrit primary instances`

* In the `Target Groups` section:
    - `production-P1-H` stands
      for `Target Group registering the Primary1 Gerrit instance listening over HTTP`
    - `production-R-GS` stands
      for `Target Group registering the Replica Gerrit instances listening over Git and SSH`

#### error_log
The 'error_log' might or might not be available depending on which version of
gerrit is being deployed.
From gerrit 3.3 it will always be available.
Prior to that it will be available from:

* stable-3.0 -> starting from 3.0.13
* stable-3.1 -> starting from 3.1.10
* stable-3.2 -> starting from 3.2.5

When the `error_log` is not available, Gerrit will still output the same content
to standard error. Refer to the [standard error section](#standard-error).

#### Standard error
Different recipes deploy different services to ECS (please refer to the
documentation of each recipe for details on what services are actually deployed).

Every ECS service will stream anything outputted to stderr to cloudwatch, to a
stream name that will take the form of:

```
{environmentName}/{serviceName}/{taskId}
```

For example, given the `gerrit-primary` service running task
`bb21cb504ca44150b770ca05e922e332`, on the `test` environment, the stderr will
be streamed to:

```
test/gerrit-primary/bb21cb504ca44150b770ca05e922e332
```

The task name can be found in the Amazon ECS console's `Task` section.

## Operations

A set of utilities to perform operational tasks is also provided.
Refer to the relevant [documentation](./operations/Operations.md) for details on this.
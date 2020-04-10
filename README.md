## Gerrit AWS Templates
Those are a collection of [AWS CloudFormation](https://aws.amazon.com/cloudformation/)
templates and scripts to deploy Gerrit in AWS.

The aim is to provide some guidelines and example on how to deploy different Gerrit
setups in the Cloud using AWS as provider.

## Outline

- [Overview](#overview)
- [Pre-requisites](#pre-requisites)
- [Templates](#templates)

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

## Templates

* [Standalone Gerrit master sandbox with LDAP authentication](/single-master/README.md)
* [Gerrit master and slave sandbox with LDAP authentication](/master-slave/README.md)

## Development

### Python checks and format

Make sure you have installed [flake8](https://pypi.org/project/flake8/) and
[autopep8](https://pypi.org/project/autopep8/) to check and enforce
[code style](https://www.python.org/dev/peps/pep-0008/) of the Python code.

Use the following command to check the style:

```
make py-check-style
```

And the following command to auto-format Python code:

```
make py-format
```

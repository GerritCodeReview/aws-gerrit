# Monitoring

This is a set of Cloud Formation Templates and scripts to spin up a monitoring
stack.

The stack includes Prometheus, to scrape Gerrit metrics
exposed by primary and replica, and Grafana to display them.

## Prerequisites

### Import a Prometheus Bearer Token

* [Generate](https://www.uuidgenerator.net/) a Token
 Import the Token in AWS secret manager with the provided script [here](../Secrets.md#prometheus-bearer-token)
* Add `TOKEN_VERSION` to the main cookbook `setup.env`
* Its value is the last part of the secret ARN, `gXpAFL` in this case

### How to run it

From the main cookbook run: `make service-monitoring`

### Access your Prometheus instance

Get the URL of your Prometheus instance this way:

```
aws cloudformation describe-stacks \
  --stack-name <SERVICE_PROMETHEUS_STACK_NAME> \
  | grep -A1 '"OutputKey": "CanonicalWebUrl"' \
  | grep OutputValue \
  | cut -d'"' -f 4
```

### Access your Grafana instance

Get the URL of your Prometheus instance this way:

```
aws cloudformation describe-stacks \
  --stack-name <SERVICE_PROMETHEUS_STACK_NAME> \
  | grep -A1 '"OutputKey": "CanonicalWebUrl"' \
  | grep OutputValue \
  | cut -d'"' -f 4
```

The default credentials are:
* user `admin`
* password `admin`

### Docker

Refer to the [Docker](../Docker.md) section for information on how to setup docker or how to publish images
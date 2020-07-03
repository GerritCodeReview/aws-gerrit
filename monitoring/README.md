# Monitoring

This is a set of Cloud Formation Templates and scripts to spin up a monitoring
stack.

The stack includes Prometheus, to scrape Gerrit metrics
exposed by master and slave, and Grafana to display them.

## Prerequisites

### Import a Prometheus Bearer Token

* [Generate](https://www.uuidgenerator.net/) a Token
* Import the Token in AWS secret manager with the provided script:
```
> add_prometheus_secrets_to_aws_secret_manager.sh <yourToken>
  Adding Prometheus Bearer Token...
  {
      "ARN": "arn:aws:secretsmanager:us-east-1:<yourAccountId>:secret:gerrit_secret_prometheus_bearer_token-gXpAFL",
      "Name": "gerrit_secret_test_prometheus_bearer_token",
      "VersionId": "e19310a4-8078-4bdb-90b4-74ead48e4339"
  }
```
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
# Gerrit Master-Slave

This set of Templates provide all the components to deploy a single Gerrit master
and a single Gerrit slave in ECS

## Architecture

Four templates are provided in this example:
* `cf-cluster`: define the ECS cluster and the networking stack
* `cf-service-master`: define the service stack running Gerrit master
* `cf-service-slave`: define the service stack running Gerrit slave
* `cf-dns-route`: define the DNS routing for the service

### Networking

* Single VPC:
 * CIDR: 10.0.0.0/16
* Single Availability Zone
* 1 public Subnets:
 * CIDR: 10.0.0.0/24
* 1 public NLB exposing:
 * Gerrit master HTTP on port 8080
 * Gerrit master SSH on port 29418
* 1 public NLB exposing:
 * Gerrit slave HTTP on port 8081
 * Gerrit slave SSH on port 39418
 * SSH agent on port 1022
 * Git daemon on port 9418
* 1 Internet Gateway
* 2 type A alias DNS entry, for Gerrit master and slave
* A SSL certificate available in [AWS Certificate Manager](https://aws.amazon.com/certificate-manager/)

### Data persistency

* EBS volumes for:
  * Indexes
  * Caches
  * Data
  * Git repositories

### Deployment type

* Latest Gerrit version deployed using the official [Docker image](https://hub.docker.com/r/gerritcodereview/gerrit)
* Application deployed in ECS on a single EC2 instance

### Logging

* Gerrit `error_log` is exported in a Log Group in CloudWatch
* Other Gerrit logs still need to be exported

### Monitoring

* Standard CloudWatch monitoring metrics for each component

## How to run it

### 0 - Prerequisites

Follow the steps described in the [Prerequisites](../Prerequisites.md) section

### 1 - Configuration

Please refer to the [configuration docs](../Configuration.md) to understand how to set up the
configuration and what common configuration values are needed.
On top of that, you might set the additional parameters, specific for this recipe.

#### Environment

Configuration values affecting deployment environment and cluster properties

* `SERVICE_MASTER_STACK_NAME`: Optional. Name of the master service stack. `gerrit-service-master` by default.
* `SERVICE_SLAVE_STACK_NAME`: Optional. Name of the slave service stack. `gerrit-service-slave` by default.
* `MASTER_SUBDOMAIN`: Optional. Name of the master sub domain. `gerrit-master-demo` by default.
* `SLAVE_SUBDOMAIN`: Optional. Name of the slave sub domain. `gerrit-slave-demo` by default.
* `CLUSTER_DESIRED_CAPACITY`: Optional. Number of EC2 instances composing the cluster. `1` by default.

*NOTE*: if you are planning to run the monitoring stack, set the
`CLUSTER_DESIRED_CAPACITY` value to at least 2. The resources provided by
a single EC2 instance won't be enough for all the services that will be ran*

* `PROMETHEUS_SUBDOMAIN`: Optional. Prometheus subdomain. For example: `<AWS_PREFIX>-prometheus`
* `GRAFANA_SUBDOMAIN`: Optional. Grafana subdomain. For example: `<AWS_PREFIX>-grafana`

### 2 - Deploy

* Create the cluster, services and DNS routing stacks:

```
make [AWS_REGION=a-valid-aws-region] [AWS_PREFIX=some-cluster-prefix] create-all
```

The optional `AWS_REGION` and `AWS_REFIX` allow you to define where it will be deployed and what it will be named.

It might take several minutes to build the stack.
You can monitor the creations of the stacks in [CloudFormation](https://console.aws.amazon.com/cloudformation/home)

* *NOTE*: the creation of the cluster needs an EC2 key pair are useful when you need to connect
to the EC2 instances for troubleshooting purposes. The key pair is automatically generated
and stored in a `pem` file on the current directory.
To use when ssh-ing into your instances as follow: `ssh -i cluster-keys.pem ec2-user@<ec2_instance_ip>`

### Cleaning up

```
make [AWS_REGION=a-valid-aws-region] [AWS_PREFIX=some-cluster-prefix] delete-all
```

The optional `AWS_REGION` and `AWS_REFIX` allow you to specify exactly which stack you target for deletion.

Note that this will *not* delete:
* Secrets stored in Secret Manager
* SSL certificates
* ECR repositories

### Access your Gerrit instances

Get the URL of your Gerrit master instance this way:

```
aws cloudformation describe-stacks \
  --stack-name <SERVICE_MASTER_STACK_NAME> \
  | grep -A1 '"OutputKey": "CanonicalWebUrl"' \
  | grep OutputValue \
  | cut -d'"' -f 4
```

Similarly for the slave:
```
aws cloudformation describe-stacks \
  --stack-name <SERVICE_SLAVE_STACK_NAME> \
  | grep -A1 '"OutputKey": "CanonicalWebUrl"' \
  | grep OutputValue \
  | cut -d'"' -f 4
```

Gerrit master instance ports:
* HTTP `8080`
* SSH `29418`

Gerrit slave instance ports:
* HTTP `9080`
* SSH `39418`

### Monitoring

* Standard CloudWatch monitoring metrics for each component
* Optionally Prometheus and Grafana stack (see [here](../monitoring/README.md))

## Monitoring

If you want to monitor your system, you can add a Prometheus and Grafana stack.
[Here](../monitoring/README.md) you can find the details on how to add it.

### Docker

Refer to the [Docker](../Docker.md) section for information on how to setup docker or how to publish images
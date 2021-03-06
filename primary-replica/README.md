# Gerrit Primary-Replica

This set of Templates provide all the components to deploy a single Gerrit primary
and a single Gerrit replica in ECS

## Architecture

Five templates are provided in this example:
* `cf-cluster`: define the ECS cluster and the networking stack
* `cf-service-primary`: define the service stack running Gerrit primary
* `cf-service-replica`: define the service stack running Gerrit replica
* `cf-dns-route`: define the DNS routing for the service
* `cf-dashboard`: define the CloudWatch dashboard for the services

### Networking

* Single VPC:
 * CIDR: 10.0.0.0/16
* Single Availability Zone
* 1 public Subnets:
 * CIDR: 10.0.0.0/24
* 1 public NLB exposing:
 * Gerrit primary HTTP on port 8080
 * Gerrit primary SSH on port 29418
* 1 public NLB exposing:
 * Gerrit replica HTTP on port 8081
 * Gerrit replica SSH on port 39418
 * SSH agent on port 1022
 * Git daemon on port 9418
* 1 Internet Gateway
* 2 type A alias DNS entry, for Gerrit primary and replica
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
* Application level CloudWatch monitoring can be enabled as described [here](../Configuration.md#cloudwatch-monitoring)
* Optionally Prometheus and Grafana stack (see [here](../monitoring/README.md))

## How to run it

### 0 - Prerequisites

Follow the steps described in the [Prerequisites](../Prerequisites.md) section

### 1 - Configuration

Please refer to the [configuration docs](../Configuration.md) to understand how to set up the
configuration and what common configuration values are needed.
On top of that, you might set the additional parameters, specific for this recipe.

#### Environment

Configuration values affecting deployment environment and cluster properties

* `SERVICE_PRIMARY_STACK_NAME`: Optional. Name of the primary service stack. `gerrit-service-primary` by default.
* `SERVICE_REPLICA_STACK_NAME`: Optional. Name of the replica service stack. `gerrit-service-replica` by default.
* `DASHBOARD_STACK_NAME` : Optional. Name of the dashboard stack. `gerrit-dashboard` by default.
* `PRIMARY_SUBDOMAIN`: Optional. Name of the primary sub domain. `gerrit-primary-demo` by default.
* `REPLICA_SUBDOMAIN`: Optional. Name of the replica sub domain. `gerrit-replica-demo` by default.
* `GERRIT_PRIMARY_INSTANCE_ID`: Optional. Identifier for the Gerrit primary instance.
"gerrit-primary-replica-PRIMARY" by default.
* `GERRIT_REPLICA_INSTANCE_ID`: Optional. Identifier for the Gerrit replica instance.
"gerrit-primary-replica-REPLICA" by default.
* `GERRIT_VOLUME_ID` : Optional. Id of an extisting EBS volume. If empty, a new volume
for Gerrit data will be created
* `GERRIT_VOLUME_SNAPSHOT_ID` : Optional. Ignored if GERRIT_VOLUME_ID is not empty. Id of
the EBS volume snapshot used to create new EBS volume for Gerrit data.
* `GERRIT_VOLUME_SIZE_IN_GIB`: Optional. The size of the Gerrit data volume, in GiBs. `10` by default.

*NOTE*: if you are planning to run the monitoring stack, set the
`PRIMARY_MAX_COUNT` value to at least 2. The resources provided by
a single EC2 instance won't be enough for all the services that will be ran*

* `PROMETHEUS_SUBDOMAIN`: Optional. Prometheus subdomain. For example: `<AWS_PREFIX>-prometheus`
* `GRAFANA_SUBDOMAIN`: Optional. Grafana subdomain. For example: `<AWS_PREFIX>-grafana`

##### Shared filesystem for replicas

replicas share a data via an EFS filesystem which is
mounted under the `/var/gerrit/git` directory. This allows git data to persist
beyond the lifespan of a single instance and to be shared so that replicas can
scale down and up according to needs.

* `REPLICA_FILESYSTEM_ID`: Optional. An existing EFS filesystem id to mount on replicas.

    If empty, a new EFS will be created to store git data.
    Setting this value is required when deploying a dual-primary cluster using
    existing data as well as performing blue/green deployments.
    The nested stack will be *retained* when the cluster is deleted, so that
    existing data can be used to perform blue/green deployments.

* `REPLICA_FILESYSTEM_THROUGHPUT_MODE`: Optional. The throughput mode for the file system to be created.
default: `bursting`. More info [here](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-efs-filesystem.html)

* `REPLICA_FILESYSTEM_PROVISIONED_THROUGHPUT_IN_MIBPS`: Optional. Only used when `REPLICA_FILESYSTEM_THROUGHPUT_MODE` is set to `provisioned`.
default: `256`.

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

Get the URL of your Gerrit primary instance this way:

```
aws cloudformation describe-stacks \
  --stack-name <SERVICE_PRIMARY_STACK_NAME> \
  | grep -A1 '"OutputKey": "CanonicalWebUrl"' \
  | grep OutputValue \
  | cut -d'"' -f 4
```

Similarly for the replica:
```
aws cloudformation describe-stacks \
  --stack-name <SERVICE_REPLICA_STACK_NAME> \
  | grep -A1 '"OutputKey": "CanonicalWebUrl"' \
  | grep OutputValue \
  | cut -d'"' -f 4
```

Gerrit primary instance ports:
* HTTP `8080`
* SSH `29418`

Gerrit replica instance ports:
* HTTP `9080`
* SSH `39418`

### Docker

Refer to the [Docker](../Docker.md) section for information on how to setup docker or how to publish images

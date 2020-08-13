# Gerrit dual-master in High-Availability

This set of templates provides all the components to deploy a Gerrit dual-master
in HA in ECS. The 2 masters will share the Git repositories via NFS, using EFS.

## Architecture

The following templates are provided in this example:
* `cf-cluster`: define the ECS cluster and the networking stack
* `cf-service-master`: define the service stack running the gerrit master
* `cf-dns-route`: define the DNS routing for the service
* `cf-service-slave`: define the service stack running the gerrit replica
* `cf-service-lb`: define the LBs in front of gerrit masters (this includes haproxy as well as NLB)

When the recipe enables the replication_service (see [docs](#replication-service))
then these additional templates will be executed:

* `cf-service-replication`: Define a replication stack that will allow git replication
over the EFS volume, which is mounted by the master instances.

### Networking

* Single VPC:
 * CIDR: 10.0.0.0/16
* Single Availability Zone
* 1 public Subnets:
 * CIDR: 10.0.0.0/24
* 1 public NLB exposing:
 * Gerrit master 1 HTTP on port 8080
 * Gerrit master 1 SSH on port 29418
* 1 public NLB exposing:
 * Gerrit master 2 HTTP on port 8081
 * Gerrit master 2 SSH on port 39418
* 1 Internet Gateway
* 2 type A alias DNS entry, for Gerrit master 1 and 2
* A wildcard SSL certificate available in [AWS Certificate Manager](https://aws.amazon.com/certificate-manager/)

### Data persistency

* EBS volumes for:
  * Indexes
  * Caches
  * Logs
* EFS volume:
  * Share Git repositories between masters
  * Share Web sessions between masters

*NOTE*: This stack uses EFS in provisioned mode, which is a better setting for large repos
(> 1GB uncompressed) since it provides a lower latency compared to the burst mode.
However, it has some [costs associated](https://aws.amazon.com/efs/pricing/).
If you are dealing with small repos, you can switch to burst mode.

### Deployment type

* Latest Gerrit version deployed using the official [Docker image](https://hub.docker.com/r/gerritcodereview/gerrit)
* Application deployed in ECS on a single EC2 instance

### Logging

* All the logs are forwarded to AWS CloudWatch in the LogGroup with the cluster
  stack name

### Monitoring

* Standard CloudWatch monitoring metrics for each component
* Application level CloudWatch monitoring can be enabled as described [here](../Configuration.md#cloudwatch-monitoring)
* Prometheus and Grafana stack is currently not available for dual-master, but a change is in progress to allow this
 (see [Issue 12979](https://bugs.chromium.org/p/gerrit/issues/detail?id=12979))

## How to run it

### 0 - Prerequisites

Follow the steps described in the [Prerequisites](../Prerequisites.md) section

### 1 - Configuration

Please refer to the [configuration docs](../Configuration.md) to understand how to set up the
configuration and what common configuration values are needed.
On top of that, you might set the additional parameters, specific for this recipe.

#### Environment

Configuration values affecting deployment environment and cluster properties

* `SERVICE_MASTER1_STACK_NAME`: Optional. Name of the master 1 service stack. `gerrit-service-master-1` by default.
* `SERVICE_MASTER2_STACK_NAME`: Optional. Name of the master 2 service stack. `gerrit-service-master-2` by default.
* `MASTER1_SUBDOMAIN`: Optional. Name of the master 1 sub domain. `gerrit-master-1-demo` by default.
* `MASTER2_SUBDOMAIN`: Optional. Name of the master 2 sub domain. `gerrit-master-2-demo` by default.
* `CLUSTER_DESIRED_CAPACITY`: Optional. Number of EC2 instances composing the cluster. `1` by default.
* `HTTP_HOST_PORT_MASTER1`: Optional. Gerrit Host HTTP port for master1 (must be different from master2). `9080` by default.
* `SSH_HOST_PORT_MASTER1:`: Optional. Gerrit Host SSH port for master1 (must be different from master2). `29418` by default.
* `HTTP_HOST_PORT_MASTER2`: Optional. Gerrit Host HTTP port for master2 (must be different from master1). `9080` by default.
* `SSH_HOST_PORT_MASTER2:`: Optional. Gerrit Host SSH port for master2 (must be different from master1). `29418` by default.
* `SLAVE_SUBDOMAIN`: Mandatory. The subdomain of the Gerrit slave. For example: `<AWS_PREFIX>-slave`
* `LB_SUBDOMAIN`: Mandatory. The subdomain of the Gerrit load balancer. For example: `<AWS_PREFIX>-dual-master`
* `FILESYSTEM_THROUGHPUT_MODE`: Optional. The throughput mode for the file system to be created.
default: `bursting`. More info [here](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-efs-filesystem.html)
* `FILESYSTEM_PROVISIONED_THROUGHPUT_IN_MIBPS`: Optional. Only used when `FILESYSTEM_THROUGHPUT_MODE` is set to `provisioned`.
default: `256`.

* `GERRIT_SLAVE_INSTANCE_ID`: Optional. Identifier for the Gerrit slave instance.
"gerrit-dual-master-SLAVE" by default.
* `GERRIT_MASTER1_INSTANCE_ID`: Optional. Identifier for the Gerrit master1 instance.
"gerrit-dual-master-MASTER1" by default.
* `GERRIT_MASTER2_INSTANCE_ID`: Optional. Identifier for the Gerrit master2 instance.
"gerrit-dual-master-MASTER2" by default.

#### REPLICATION SERVICE

* `REPLICATION_SERVICE_ENABLED`: Optional. Whether to expose a replication endpoint.
"false" by default.
* `SERVICE_REPLICATION_STACK_NAME`: Optional. The name of the replication service stack.
"git-replication-service" by default.
* `SERVICE_REPLICATION_DESIRED_COUNT`: Optional. Number of wanted replication tasks.
"1" by default.
* `GIT_REPLICATION_SUBDOMAIN`: Optional. The subdomain to use for the replication endpoint.
"git-replication" by default.

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

#### Replication-Service

Optionally this recipe can be deployed so that replication onto the share EFS volume
is available.

By setting the environment variable `REPLICATION_SERVICE_ENABLED=true`, this recipe will
set up and configure additional resources that will allow other other sites to replicate
to a specific endpoint, exposed as:

* For GIT replication
`$(GIT_REPLICATION_SUBDOMAIN).$(HOSTED_ZONE_NAME):9148`

* For Git Admin replication
`$(GIT_REPLICATION_SUBDOMAIN).$(HOSTED_ZONE_NAME):1022`

The service will persist git data on the same EFS volume mounted by the gerrit
master1 and gerrit master2.

Note that the replication endpoint is not internet-facing, thus replication requests
must be coming from a peered VPC.

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

Get the URL of your Gerrit master instances this way:

```
aws cloudformation describe-stacks \
  --stack-name <SERVICE_MASTER1_STACK_NAME> \
  | grep -A1 '"OutputKey": "CanonicalWebUrl"' \
  | grep OutputValue \
  | cut -d'"' -f 4

aws cloudformation describe-stacks \
  --stack-name <SERVICE_MASTER2_STACK_NAME> \
  | grep -A1 '"OutputKey": "CanonicalWebUrl"' \
  | grep OutputValue \
  | cut -d'"' -f 4
```

Gerrit master instance ports:
* HTTP `8080`
* SSH `29418`

### External Services

If you need to setup some external services (maybe for testing purposes, such as SMTP or LDAP),
you can follow the instructions [here](../README.md#external-services)

### Docker

Refer to the [Docker](../Docker.md) section for information on how to setup docker or how to publish images

# Gerrit dual-primary in High-Availability

This set of templates provides all the components to deploy a Gerrit dual-primary
in HA in ECS. The 2 primaries will share the Git repositories via NFS, using EFS.

## Architecture

The following templates are provided in this example:
* `cf-cluster`: define the ECS cluster and the networking stack
* `cf-service-primary`: define the service stack running the gerrit primary
* `cf-dns-route`: define the DNS routing for the service
* `cf-service-replica`: define the service stack running the gerrit replica
* `cf-service-lb`: define the LBs in front of gerrit primaries (this includes haproxy as well as NLB)
* `cf-dashboard`: define the CloudWatch dashboard for the services

When the recipe enables the replication_service (see [docs](#replication-service))
then these additional templates will be executed:

* `cf-service-replication`: Define a replication stack that will allow git replication
over the EFS volume, which is mounted by the primary instances.

### Networking

* Single VPC:
 * CIDR: 10.0.0.0/16
* Single Availability Zone
* 1 public Subnets:
 * CIDR: 10.0.0.0/24
* 1 public NLB exposing:
 * Gerrit primary 1 HTTP on port 8080
 * Gerrit primary 1 SSH on port 29418
* 1 public NLB exposing:
 * Gerrit primary 2 HTTP on port 8081
 * Gerrit primary 2 SSH on port 39418
* 1 Internet Gateway
* 2 type A alias DNS entry, for Gerrit primary 1 and 2
* A wildcard SSL certificate available in [AWS Certificate Manager](https://aws.amazon.com/certificate-manager/)

### Data persistency

* EBS volumes for:
  * Indexes
  * Caches
  * Logs
* EFS volume:
  * Share Git repositories between primaries
  * Share Web sessions between primaries

*NOTE*: This stack uses EFS in provisioned mode, which is a better setting for large repos
(> 1GB uncompressed) since it provides a lower latency compared to the burst mode.
However, it has some [costs associated](https://aws.amazon.com/efs/pricing/).
If you are dealing with small repos, you can switch to burst mode.

#### Deploying using pre-existing data.

Gerrit stores information in two volumes: git data (and possibly websessions,
when not using multi-site) are shared across Gerrit nodes and therefore
persisted in the EFS volume, whilst cache, logs, plugins data and indexes are
local to each specific Gerrit node and thus stored in the EBS volume.

In order to deploy a Gerrit instance that runs on pre-existing data, the EFS
volume and an EBS snapshot need to be specified in the `setup.env` file(see
[configuration](#environment) for more information on how to do this).

Referring to persistent volumes allows to perform [blue-green deployments](#bluegreen-deployment).

### Deployment type

* Latest Gerrit version deployed using the official [Docker image](https://hub.docker.com/r/gerritcodereview/gerrit)
* Application deployed in ECS on a single EC2 instance

#### Blue/Green deployment

When a dual-primary stack is created, unless otherwise specified, a new EFS is
created and a two new empty EBSs are attached to primary1 and primary2,
respectively.

In a [blue/green deployment](https://en.wikipedia.org/wiki/Blue-green_deployment)
scenario, this initial stack is called the *blue* stack.

```bash
make AWS_REGION=us-east-1 AWS_PREFIX=gerrit-blue create-all
```

Later on (days, weeks, months), the need of a change arises, for which a new
version of the cluster needs to be deployed: this will be the _green_ stack and
it will need to be deployed as such:

1. Take primary1 EBS snapshot of volume attached to /dev/xvdg (note, this needs
to be done in a read only window). Ideally this step is already performed
regularly by a backup script.

2. Update the `setup.env` to point to existing volumes, for example:

```bash
FILESYSTEM_ID=fs-c621b733
GERRIT_VOLUME_SNAPSHOT_ID=snap-0afa165bdf4881915
```

If the network stack was created as part of this deployment (i.e. a new VPC was
created as part of this deployment), then you need to set network resources so
that the green stack can be deployed in the same VPC, for example:

```bash
VPC_ID=vpc-08d2159c53f7a1ff5
INTERNET_GATEWAY_ID=igw-0c0577829910ce7f3
SUBNET_ID=subnet-05efd67802b1cbd5b
```

3. Deploy the *green* stack:

```bash
make AWS_REGION=us-east-1 AWS_PREFIX=gerrit-green create-all
```

4. Once the green stack comes up, Gerrit will start reindexing the changes
that have been created between the time the EBS snapshot was taken and now.
This will happen in background and might take some time depending on how old
the snapshot was.

Once you are happy the green stack is aligned and healthy you can switch the
Route53 DNS to the new green stack.

5. You can leave the blue stack running as long as you want, so that you can
always rollback to it. Once ready you can delete the blue stack as follows:

 ```bash
 make AWS_REGION=us-east-1 AWS_PREFIX=gerrit-blue delete-all
 ```

Note that, even if the EFS resources were created as part of the blue stack,
they will be retained during the stack deletion, so that they can still be used
by the green stack.

This includes EFS as well as VPC resources (if they were created as part of the
blue stack).

### Logging

* All the logs are forwarded to AWS CloudWatch in the LogGroup with the cluster
  stack name

### Monitoring

* Standard CloudWatch monitoring metrics for each component
* Application level CloudWatch monitoring can be enabled as described [here](../Configuration.md#cloudwatch-monitoring)
* Prometheus and Grafana stack is currently not available for dual-primary, but a change is in progress to allow this
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

* `SERVICE_PRIMARY1_STACK_NAME`: Optional. Name of the primary 1 service stack. `gerrit-service-primary-1` by default.
* `SERVICE_PRIMARY2_STACK_NAME`: Optional. Name of the primary 2 service stack. `gerrit-service-primary-2` by default.
* `DASHBOARD_STACK_NAME` : Optional. Name of the dashboard stack. `gerrit-dashboard` by default.
* `PRIMARY1_SUBDOMAIN`: Optional. Name of the primary 1 sub domain. `gerrit-primary-1-demo` by default.
* `PRIMARY2_SUBDOMAIN`: Optional. Name of the primary 2 sub domain. `gerrit-primary-2-demo` by default.
* `HTTP_HOST_PORT_PRIMARY1`: Optional. Gerrit Host HTTP port for primary1 (must be different from primary2). `9080` by default.
* `SSH_HOST_PORT_PRIMARY1:`: Optional. Gerrit Host SSH port for primary1 (must be different from primary2). `29418` by default.
* `HTTP_HOST_PORT_PRIMARY2`: Optional. Gerrit Host HTTP port for primary2 (must be different from primary1). `9080` by default.
* `SSH_HOST_PORT_PRIMARY2:`: Optional. Gerrit Host SSH port for primary2 (must be different from primary1). `29418` by default.
* `REPLICA_SUBDOMAIN`: Mandatory. The subdomain of the Gerrit replica. For example: `<AWS_PREFIX>-replica`
* `LB_SUBDOMAIN`: Mandatory. The subdomain of the Gerrit load balancer. For example: `<AWS_PREFIX>-dual-primary`
* `PRIMARY_FILESYSTEM_THROUGHPUT_MODE`: Optional. The throughput mode for the primary file system to be created.
default: `bursting`. More info [here](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-efs-filesystem.html)
* `PRIMARY_FILESYSTEM_PROVISIONED_THROUGHPUT_IN_MIBPS`: Optional. Only used when `PRIMARY_FILESYSTEM_THROUGHPUT_MODE` is set to `provisioned`.
default: `256`.

* `GERRIT_REPLICA_INSTANCE_ID`: Optional. Identifier for the Gerrit replica instance.
"gerrit-dual-primary-REPLICA" by default.
* `GERRIT_PRIMARY1_INSTANCE_ID`: Optional. Identifier for the Gerrit primary1 instance.
"gerrit-dual-primary-PRIMARY1" by default.
* `GERRIT_PRIMARY2_INSTANCE_ID`: Optional. Identifier for the Gerrit primary2 instance.
"gerrit-dual-primary-PRIMARY2" by default.

* `HA_PROXY_DESIRED_COUNT`: Optional. Desired number of haproxy services.
"2" by default. Minimum: "2".

*Note* ha-proxies are running on ec2 instances with a ratio of 1 to 1: each
ec2 node hosts one and only one ha-proxy. By increasing the number of desired
ha-proxies then, the size of the autoscaling group hosting them also increases
accordingly.

* `HA_PROXY_MAX_COUNT`: Optional. Maximum number of EC2 instances in the haproxy autoscaling group.
"2" by default. Minimum: "2".

* `PRIMARY_MAX_COUNT`: Optional. Maximum number of EC2 instances in the primary autoscaling group.
"2" by default. Minimum: "2".

* `GERRIT_VOLUME_SNAPSHOT_ID` : Optional. Id of the EBS volume snapshot used to
create new EBS volume for Gerrit data. A new volume will be created for each
primary, based on this snapshot.

Note that, differently from other recipes, dual-primary does not support the
`GERRIT_VOLUME_ID` parameter, since it wouldn't be possible to mount the same
EBS on multiple EC2 instances.

* `GERRIT_VOLUME_SIZE_IN_GIB`: Optional. The size of the Gerrit data volume, in GiBs. `10` by default.
* `FILESYSTEM_ID`: Optional. An existing EFS filesystem id.

    If empty, a new EFS will be created to store git data.
    Setting this value is required when deploying a dual-primary cluster using
    existing data as well as performing blue/green deployments.
    The nested stack will be *retained* when the cluster is deleted, so that
    existing data can be used to perform blue/green deployments.

* `AUTOREINDEX_POLL_INTERVAL`. Optional. Interval between reindexing of all changes, accounts and groups.
Default: `10m`
high-availability docs [here](https://gerrit.googlesource.com/plugins/high-availability/+/refs/heads/master/src/main/resources/Documentation/config.md)

##### Shared filesystem for replicas

Similarly to primary nodes, replicas share a data via an EFS filesystem which is
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

##### Auto Scaling of replicas instances

Gerrit replicas have the ability to scale in or out automatically to accommodate
to the increase or decrease of traffic. The traffic might be typically coming
from build or test jobs executed by some sort of automated build pipeline.

Since they all [share the same git data over EFS](#shared-filesystem-for-replicas),
replicas are immediately ready to serve traffic as soon as they come up and
register behind the loadbalancer.

There is a 1 to 1 relationship between replica and EC2 instances: on each EC2
instance in the 'replica' ASG, runs one and only one replica task.
Because of this, when specifying the capacity for replicas (minimum, desired and
maximum), they will both configure for the capacity of tasks as well as the
capacity of the ASG, since they always need to be in sync.

The scaling policy adds or removes capacity as required to keep the average CPU
Usage (of the replica service) close to the specified target value.

These are the available settings:

* `REPLICA_AUTOSCALING_MIN_CAPACITY` Optional. The minimum number of tasks that
replicas should scale in to. This is also the minimum number of EC2 instances in
the replica ASG
default: *1*

* `REPLICA_AUTOSCALING_DESIRED_CAPACITY` Optional. The desired number of
replica tasks to run. This is also the desired number of EC2 instances in the
replica ASG.
default: *1*

* `REPLICA_AUTOSCALING_MAX_CAPACITY` Optional. The maximum number of tasks that
replicas should scale out to. This is also the maximum number of EC2 instances
in the replica ASG
default: *2*

* `REPLICA_AUTOSCALING_SCALE_IN_COOLDOWN` Optional. The amount of time, in
seconds, after a scale-in activity completes before another scale-in activity
can start
default: *300* seconds

* `REPLICA_AUTOSCALING_SCALE_OUT_COOLDOWN` Optional. The amount of time, in
seconds, to wait for a previous scale-out activity to take effect
default: *300* seconds

* `REPLICA_AUTOSCALING_TARGET_CPU_PERCENTAGE` Optional. Aggregate CPU
utilization target for auto-scaling. Auto-scaling will add or remove tasks in
the replica service to be as close as possible to this value

#### REPLICATION SERVICE

* `REPLICATION_SERVICE_ENABLED`: Optional. Whether to expose a replication endpoint.
"false" by default.
* `SERVICE_REPLICATION_STACK_NAME`: Optional. The name of the replication service stack.
"git-replication-service" by default.
* `SERVICE_REPLICATION_DESIRED_COUNT`: Optional. Number of wanted replication tasks.
"1" by default.
* `GIT_REPLICATION_SUBDOMAIN`: Optional. The subdomain to use for the replication endpoint.
"git-replication" by default.

It is also posssible to replicate *to* an extra target by providing a FQDN.
The target is expected to expose port 9148 and port 1022 for git and git admin
operations respectively.

* `REMOTE_REPLICATION_TARGET_HOST`: Optional.  The fully qualified domain name of a remote replication target.
Empty by default.

The replication service and the remote replication target represent the reading
and writing sides of Git replication: by enabling both of them, it is possible to
establish replication to a remote Git site.

#### MULTI-SITE

This recipe supports multi-site. Multi-site is a specific configuration of Gerrit
that allows it to be part of distributed multi-primary of multiple Gerrit clusters.
No storage is shared among the Gerrit sites: syncing happens thanks to two
channels:

* The `replication` plugin allow alignment of git data (see [replication service](#replication-service))
for how to enable this.
* The `multi-site` group of plugins and resources allow the coordination and the exchange
of gerrit specific events that are produced and consumed by the members of the multi-site deployment.
(See the [multi-site design](https://gerrit.googlesource.com/plugins/multi-site/+/refs/heads/stable-3.2/DESIGN.md)
for more information on this.

##### Requirements
* Kafka brokers and Zookeeper are required by this recipe and are expected to exist
and accessible with server-side TLS security enabled by the primary instances
resulting from the deployment of this recipe.
* Replication service must be enabled to allow syncing of Git data.

These are the parameters that can be specified to enable/disable multi-site:

* `MULTISITE_ENABLED`: Optional. Whether this Gerrit is part of a multi-site
cluster deployment. "false" by default.
* `MULTISITE_ZOOKEEPER_CONNECT_STRING`: Required when "MULTISITE_ENABLED=true".
Connection string to Zookeeper.
* `MULTISITE_KAFKA_BROKERS`: Required when "MULTISITE_ENABLED=true".
Comma separated list of Kafka broker hosts (host:port)
to use for publishing events to the message broker.
* `MULTISITE_ZOOKEEPER_ROOT_NODE` Optional. Root node to use in Zookeeper to
store/retrieve information.
Constraint: a slash-separated ('/') string not starting with a slash ('/')
"gerrit/multi-site" by default.
* `MULTISITE_GLOBAL_PROJECTS`: Optional. Comma separated list of patterns (see [projects.pattern](https://gerrit.googlesource.com/plugins/multi-site/+/refs/heads/stable-3.2/src/main/resources/Documentation/config.md))
to specify which projects are available across all sites. This parametes applies to both multi-site
and replication service remote destinations.
Empty by default which means that all projects are available across all sites.

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
primary1 and gerrit primary2.

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
* EFS stack
* VPC and subnets (if created as part of this deployment, rather than externally
provided)

Note that you can completely delete the stack, including explicitly retained
resources such as the EFS Git filesystem, VPC and subnets, by issuing the more
aggressive command:

```
make [AWS_REGION=a-valid-aws-region] [AWS_PREFIX=some-cluster-prefix] delete-all-including-retained-stack
```

Note that this will execute a prompt to confirm your choice:

```
* * * * WARNING * * * * this is going to completely destroy the stack, including git data.

Are you sure you want to continue? [y/N]
```

If you want to automate this programmatically you can just pipe the `yes`
command to the make:

```
yes | make [AWS_REGION=a-valid-aws-region] [AWS_PREFIX=some-cluster-prefix] delete-all-including-retained-stack
```

### Access your Gerrit instances

Get the URL of your Gerrit primary instances this way:

```
aws cloudformation describe-stacks \
  --stack-name <SERVICE_PRIMARY1_STACK_NAME> \
  | grep -A1 '"OutputKey": "CanonicalWebUrl"' \
  | grep OutputValue \
  | cut -d'"' -f 4

aws cloudformation describe-stacks \
  --stack-name <SERVICE_PRIMARY2_STACK_NAME> \
  | grep -A1 '"OutputKey": "CanonicalWebUrl"' \
  | grep OutputValue \
  | cut -d'"' -f 4
```

Gerrit primary instance ports:
* HTTP `8080`
* SSH `29418`

### External Services

If you need to setup some external services (maybe for testing purposes, such as SMTP or LDAP),
you can follow the instructions [here](../README.md#external-services)

### Docker

Refer to the [Docker](../Docker.md) section for information on how to setup docker or how to publish images

# Gerrit dual-primary in High-Availability

This set of templates provides all the components to deploy a Gerrit dual-primary
in HA in ECS. The 2 primaries will share the Git repositories via NFS, using EFS.

## Architecture

The following templates are provided in this example:
* `cf-cluster`: define the ECS cluster and the networking stack
* `cf-service-primary`: define the service stack running the gerrit primary
* `cf-dns-route`: define the DNS routing for the service
* `cf-service-replica`: define the service stack running the gerrit replica
* `cf-dashboard`: define the CloudWatch dashboard for the services

When the recipe enables the replication_service (see [docs](#replication-service))
then these additional templates will be executed:

* `cf-service-replication`: Define a replication stack that will allow git replication
over the EFS volume, which is mounted by the primary instances.

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
PRIMARY_FILESYSTEM_ID=fs-93514727
REPLICA_FILESYSTEM_ID=fs-9c514728
GERRIT_VOLUME_SNAPSHOT_ID=snap-048a5c2dfc14a81eb
```

If the network stack was created as part of this deployment (i.e. a new VPC was
created as part of this deployment), then you need to set network resources so
that the green stack can be deployed in the same VPC, for example:

```bash
VPC_ID=	vpc-03292278512e783c7
INTERNET_GATEWAY_ID=igw-0cb5b144c294f9411

SUBNET1_ID=subnet-066065ea55fda52cf
SUBNET1_AZ=us-east-1a
SUBNET1_CIDR=10.0.0.0/24

SUBNET2_ID=subnet-0fefe45d89ce02b31
SUBNET2_AZ=us-east-1b
SUBNET2_CIDR=10.0.32.0/24
```

Note that if the refs-db dynamodb tables were created as part of the initial
stack (`CREATE_REFS_DB_TABLES` was set to `true`), you will need to explicitly
set it to `false` to avoid attempting to create the same tables again.

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
  stack name. Please refer to the general [logging documentation](../README.md#logging)
  for further information on logging.

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
* `REPLICA_SUBDOMAIN`: Mandatory. The subdomain of the Gerrit replica. For example: `<AWS_PREFIX>-replica`
* `PRIMARIES_GERRIT_SUBDOMAIN`: Mandatory. The subdomain of the lb serving traffic to both primary gerrit instances.
   For example: `<AWS_PREFIX>-primaries`
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

* `DYNAMODB_LOCKS_TABLE_NAME`. Optional. The name of the dynamoDB table used to
  store distribute locking.
  Default: `locksTable`
  See DynamoDB lock client [here](https://github.com/awslabs/amazon-dynamodb-lock-client)

* `DYNAMODB_REFS_TABLE_NAME`. Optional. The name of the dynamoDB table used to
  store git refs and their associated sha1.
  Default: `refsDb`

* `CREATE_REFS_DB_TABLES`. Optional. Whether to create the DynamoDB refs and
  lock tables.
  Default: `false`

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

Now, tasks in the provisioning state that cannot find sufficient resources on
the existing instances will automatically trigger the capacity provider to scale
out the replica ASG. As more EC2 instances become available, tasks in the
provisioning state will get placed onto those instances, reducing the number of
tasks in provisioning.

Conversely, as the average CPU usage (of the replica service) drops under the
specified target value, and replica tasks get removed, the capacity provider
will reduce the number of EC2 instances too.

Note that only EC2 instances that are not running any replica task will scale in.

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

* `REPLICA_CAPACITY_PROVIDER_TARGET` Optional. The target capacity value for the
capacity provider of replicas (must be > 0 and <= 100).
default: *100*

   Setting this value to 100 means that there will be no _spare capacity_
allocated on the replica ASG:

   If 3 replica tasks are needed, then the ASG will adjust to have exactly 3 EC2

   Setting this value to less than 100 enables spare capacity in the ASG. For
example, if you set this value to 50 the scaling policy will adjust the EC2
until it is exactly twice the number of instances needed to run all of the
tasks:

   If 3 replica tasks are needed, then there ASG will adjust to 6 EC2

* `REPLICA_CAPACITY_PROVIDER_MIN_STEP_SIZE` Optional. The minimum number of EC2
instances for replicas that will scale in or scale out at one time (must be >= 1
and <= 10)
default: *1*

* `REPLICA_CAPACITY_PROVIDER_MAX_STEP_SIZE` Optional. The maximum number of EC2
instances for replicas that will scale in or scale out at one time (must be >= 1
and <= 10)
default: *1*

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
* Kafka brokers and DynamoDB are required by this recipe and are expected to exist
and accessible with server-side TLS security enabled by the primary instances
resulting from the deployment of this recipe.
* Replication service must be enabled to allow syncing of Git data.

These are the parameters that can be specified to enable/disable multi-site:

* `MULTISITE_ENABLED`: Optional. Whether this Gerrit is part of a multi-site
cluster deployment. "false" by default.
* `MULTISITE_KAFKA_BROKERS`: Required when "MULTISITE_ENABLED=true".
Comma separated list of Kafka broker hosts (host:port)
to use for publishing events to the message broker.
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
* Refs-DB DynamoDB stack (if created as part of this deployment, rather than
  externally provided))

Note that you can completely delete the stack, including explicitly retained
resources such as the EFS Git filesystem, VPC and subnets and DynamoDB stack by
issuing the more aggressive command:

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

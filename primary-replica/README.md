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

* All the logs are forwarded to AWS CloudWatch in the LogGroup with the cluster
  stack name. Please refer to the general [logging documentation](../README.md#logging)
  for further information on logging.

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
* Replica EFS stack
* VPC and subnets (if created as part of this deployment, rather than externally
provided)

### Persistent stacks

Blue/green deployment of the primary-replica recipe requires that the blue and
the green stacks are deployed within the same VPC.

In order to preserve the VPC, the IGW and the subnet upon deletion of
the blue stack, the nested network cloudformation template needs to be
protected from deletion.

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

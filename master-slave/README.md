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

* All the logs are forwarded to AWS CloudWatch in the LogGroup with the cluster
  stack name

### Monitoring

* Standard CloudWatch monitoring metrics for each component
* Prometheus and Grafana stack is currently not available for dual-master, but a change is in progress to allow this
 (see [Issue 12979](https://bugs.chromium.org/p/gerrit/issues/detail?id=12979))

### Setup

#### 0 - Prerequisites

Follow the steps described in the [Prerequisites](../Prerequisites.md) section

#### 1 - Configuration

Each recipe provides a `setup.env.template` file which is a template for configuring the Gerrit stacks.
Copy that into a `setup.env` and set the correct values for the  provided environment variables.

```bash
cp setup.env.template setup.env
```

This is the list of available parameters:

* `DOCKER_REGISTRY_URI`: Mandatory. URI of the Docker registry. See the
  [prerequisites](#prerequisites) section for more details.
* `SSL_CERTIFICATE_ARN`: Mandatory. ARN of the SSL Certificate.
* `CLUSTER_STACK_NAME`: Optional. Name of the cluster stack. `gerrit-cluster` by default.
* `SERVICE_MASTER_STACK_NAME`: Optional. Name of the master service stack. `gerrit-service-master` by default.
* `SERVICE_SLAVE_STACK_NAME`: Optional. Name of the slave service stack. `gerrit-service-slave` by default.
* `DNS_ROUTING_STACK_NAME`: Optional. Name of the DNS routing stack. `gerrit-dns-routing` by default.
* `HOSTED_ZONE_NAME`: Optional. Name of the hosted zone. `mycompany.com` by default.
* `MASTER_SUBDOMAIN`: Optional. Name of the master sub domain. `gerrit-master-demo` by default.
* `SLAVE_SUBDOMAIN`: Optional. Name of the slave sub domain. `gerrit-slave-demo` by default.
*  GERRIT_KEY_PREFIX : Optional. Secrets prefix used during the [Import into AWS Secret Manager](#import-into-aws-secret-manager).
  `gerrit_secret` by default.
* `CLUSTER_DESIRED_CAPACITY`: Optional.  Number of EC2 instances composing the cluster. `1` by default.
* `GERRIT_RAM`: RAM allocated (MiB) to the Gerrit container. `70000` by default.
* `GERRIT_CPU`: vCPU units allocated to the Gerrit container. `10240` by default.
* `GERRIT_HEAP_LIMIT`: Maximum heap size of the Java process running Gerrit, in bytes.
  See [Gerrit documentation](https://gerrit-review.googlesource.com/Documentation/config-gerrit.html#container.heapLimit)
  `35g` by default.
* `JGIT_CACHE_SIZE`: Maximum number of bytes to load and cache in memory from pack files.
  See [Gerrit documentation](https://gerrit-review.googlesource.com/Documentation/config-gerrit.html#core.packedGitLimit)
  for more details. `12g` by default.

*NOTE: if you are planning to run the monitoring stack, set the
`CLUSTER_DESIRED_CAPACITY` value to at least 2. The resources provided by
a single EC2 instance won't be enough for all the services that will be ran*

#### 2 - Deploy

This step will:
* Build and push _Gerrit_, _SSH Agent_ and _Git Daemon_ docker images to the ECR configured in your `setup.env`
* Create the cluster, services and DNS routing stacks

```
make create-all
```

It might take several minutes to build the stack.
You can monitor the creations of the stacks in [CloudFormation](https://console.aws.amazon.com/cloudformation/home)

* *NOTE*: the creation of the cluster needs an EC2 key pair are useful when you need to connect
to the EC2 instances for troubleshooting purposes. The key pair is automatically generated
and stored in a `pem` file on the current directory.
To use when ssh-ing into your instances as follow: `ssh -i cluster-keys.pem ec2-user@<ec2_instance_ip>`*

### Other operations

#### Tear down

to tear down the entire stack just run

```
make delete-all
```

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

#### External Services

If you need to setup some external services (maybe for testing purposes, such as SMTP or LDAP),
you can follow the instructions [here](../README.md#external-services)
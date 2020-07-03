# Gerrit Single Master

This set of Templates provide all the components to deploy a single Gerrit master
in ECS

## Architecture

Two templates are provided in this example:
* `cf-cluster`: define the ECS cluster and the networking stack
* `cf-service`: defined the service stack running Gerrit
* `cf-dns-route`: defined the DNS routing for the service

### Networking

* Single VPC:
 * CIDR: 10.0.0.0/16
* Single Availability Zone
* 1 public Subnets:
 * CIDR: 10.0.0.0/24
* 1 public NLB exposing:
 * HTTP on port 8080
 * SSH on port 29418
* 1 Internet Gateway
* 1 type A alias DNS entry
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
* Prometheus and Grafana stack is not available for this recipe yet. However the work has been done for
the dual-master recipe and it could be easily adapted (you can find the relevant issue
[here](https://bugs.chromium.org/p/gerrit/issues/detail?id=13092)).

## How to run it

You can find [on GerritForge's YouTube Channel](https://www.youtube.com/watch?v=zr2zCSuclIU) a
step-by-step guide on how to setup you Gerrit Code Review in AWS.

However, keep reading this guide for a more exhaustive explanation.

### 0 - Prerequisites

Follow the steps described in the [Prerequisites](../Prerequisites.md) section

### 1 - Configuration

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
* `SERVICE_STACK_NAME`: Optional. Name of the service stack. `gerrit-service` by default.
* `DNS_ROUTING_STACK_NAME`: Optional. Name of the DNS routing stack. `gerrit-dns-routing` by default.
* `HOSTED_ZONE_NAME`: Optional. Name of the hosted zone. `mycompany.com` by default.
* `SUBDOMAIN`: Optional. Name of the sub domain. `gerrit-master-demo` by default.
*  GERRIT_KEY_PREFIX : Optional. Secrets prefix used during the [Import into AWS Secret Manager](#import-into-aws-secret-manager).
  `gerrit_secret` by default.
* `GERRIT_RAM`: RAM allocated (MiB) to the Gerrit container. `70000` by default.
* `GERRIT_CPU`: vCPU units allocated to the Gerrit container. `10240` by default.
* `GERRIT_HEAP_LIMIT`: Maximum heap size of the Java process running Gerrit, in bytes.
  See [Gerrit documentation](https://gerrit-review.googlesource.com/Documentation/config-gerrit.html#container.heapLimit)
  `35g` by default.
* `JGIT_CACHE_SIZE`: Maximum number of bytes to load and cache in memory from pack files.
  See [Gerrit documentation](https://gerrit-review.googlesource.com/Documentation/config-gerrit.html#core.packedGitLimit)
  for more details. `12g` by default.

### 2 - Deploy

* Create the cluster, service and DNS routing stacks:

```
make create-all
```

It might take several minutes to build the stack.
You can monitor the creations of the stacks in [CloudFormation](https://console.aws.amazon.com/cloudformation/home)

* *NOTE*: the creation of the cluster needs an EC2 key pair are useful when you need to connect
to the EC2 instances for troubleshooting purposes. The key pair is automatically generated
and stored in a `pem` file on the current directory.
To use when ssh-ing into your instances as follow: `ssh -i cluster-keys.pem ec2-user@<ec2_instance_ip>`

### Cleaning up

```
make delete-all
```

Note that this will *not* delete:
* Secrets stored in Secret Manager
* SSL certificates
* ECR repositories

### Access your Gerrit

You Gerrit instance will be available at this URL: `http://<HOSTED_ZONE_NAME>.<SUBDOMAIN>`.

The available ports are `8080` for HTTP and `29418` for SSH.

### External Services

If you need to setup some external services (maybe for testing purposes, such as SMTP or LDAP),
you can follow the instructions [here](../README.md#external-services)

### Docker

Refer to the [Docker](../Docker.md) section for information on how to setup docker or how to publish images
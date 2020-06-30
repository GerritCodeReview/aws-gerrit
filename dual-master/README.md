# Gerrit dual-master in High-Availability

This set of templates provides all the components to deploy a Gerrit dual-master
in HA over ECS. The 2 masters will share the Git repositories via NFS, using EFS.

## Architecture

The following templates are provided in this example:
* `cf-cluster`: define the ECS cluster and the networking stack
* `cf-service-master`: define the service stack running the gerrit master
* `cf-dns-route`: define the DNS routing for the service
* `cf-service-slave`: define the service stack running the gerrit replica
* `cf-service-lb`: define the LBs in front of gerrit masters (this includes haproxy as well as NLB)

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

## How to run it

### Setup

The `setup.env.template` is an example of setup file for the creation of the stacks.

Before creating the stacks, create a `setup.env` in the `Makefile` directory and
set the correct values of the environment variables.

This is the list of available parameters:

* `DOCKER_REGISTRY_URI`: Mandatory. URI of the Docker registry. See the
  [prerequisites](#prerequisites) section for more details.
* `SSL_CERTIFICATE_ARN`: Mandatory. ARN of the wildcard SSL Certificate, covering both master nodes.
* `CLUSTER_STACK_NAME`: Optional. Name of the cluster stack. `gerrit-cluster` by default.
* `SERVICE_MASTER1_STACK_NAME`: Optional. Name of the master 1 service stack. `gerrit-service-master-1` by default.
* `SERVICE_MASTER2_STACK_NAME`: Optional. Name of the master 2 service stack. `gerrit-service-master-2` by default.
* `DNS_ROUTING_STACK_NAME`: Optional. Name of the DNS routing stack. `gerrit-dns-routing` by default.
* `HOSTED_ZONE_NAME`: Optional. Name of the hosted zone. `mycompany.com` by default.
* `MASTER1_SUBDOMAIN`: Optional. Name of the master 1 sub domain. `gerrit-master-1-demo` by default.
* `MASTER2_SUBDOMAIN`: Optional. Name of the master 2 sub domain. `gerrit-master-2-demo` by default.
* `CLUSTER_DESIRED_CAPACITY`: Optional.  Number of EC2 instances composing the cluster. `1` by default.
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

### Prerequisites

The prerequisites to run this stack are:
* a registered and correctly configured domain in
[Route53](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/getting-started.html)
* to [publish the Docker image](#publish-custom-gerrit-docker-image) with your
Gerrit configuration in AWS ECR
* to [add Gerrit secrets](#add-gerrit-secrets-in-aws-secret-manager) in AWS Secret
Manager
* an SSL Certificate in AWS Certificate Manager (you can find more information on
  how to create and handle certificates in AWS [here](https://aws.amazon.com/certificate-manager/getting-started/)

### Secrets
Make sure you have uploaded the required secrets to AWS Secret Manager.
You can follow the steps [here](../Secrets.md))

### Publish custom Gerrit Docker image

* Create the repository in the Docker registry:
  `aws ecr create-repository --repository-name aws-gerrit/gerrit`
* Set the Docker registry URI in `DOCKER_REGISTRY_URI`
* Create a `gerrit.setup` and set the correct parameters
 * An example of the possible setting are in `gerrit.setup.template`
 * The structure and parameters of `gerrit.setup` are the same as a normal `gerrit.config`
 * Refer to the [Gerrit Configuration Documentation](https://gerrit-review.googlesource.com/Documentation/config-gerrit.html)
   for the meaning of the parameters
* Add the plugins you want to install in `./gerrit/plugins`
* Publish the image: `make gerrit-publish`

### Publish custom HAProxy Docker image

* Create the HAProxy and the logging sidecar repository in the Docker registry:
  `aws ecr create-repository --repository-name aws-gerrit/haproxy`
  `aws ecr create-repository --repository-name aws-gerrit/syslog-sidecar`
* Publish the images:
  `make haproxy-publish`
  `make syslog-sidecar-publish`

### Getting Started

* Create the cluster, services and DNS routing stacks:

```
make create-all
```

*NOTE: the creation of the cluster needs an EC2 key pair are useful when you need to connect
to the EC2 instances for troubleshooting purposes. The key pair is automatically generated
and stored in a `pem` file on the current directory.
To use when ssh-ing into your instances as follow: `ssh -i cluster-keys.pem ec2-user@<ec2_instance_ip>`*

### Cleaning up

```
make delete-all
```

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

# External services

This is a list of external services that you might need to setup your stack and some suggestions
on how to easily create them.

## SMTP Server

If you need to setup a SMTP service Amazon Simple Email Service can be used.
Details how setup Amazon SES can be found [here](https://docs.aws.amazon.com/ses/latest/DeveloperGuide/send-email-set-up.html).

To correctly setup email notifications Gerrit requires ssl protocol on default port 465 to
be enabled on SMTP Server. It is possible to setup Gerrit to talk to standard SMTP port 25
but by default all EC2 instances are blocking it. To enable port 25 please follow [this](https://aws.amazon.com/premiumsupport/knowledge-center/ec2-port-25-throttle/) link.

## LDAP Server

If you need a testing LDAP server you can find details on how to easily
create one in the [LDAP folder](../ldap/README.md).

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

### Setup

The `setup.env.template` is an example of setup file for the creation of the stacks.

Before creating the stacks, create a `setup.env` in the `Makefile` directory and
correctly set the value of the environment variables.

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
* `INTERNET_GATEWAY_ID`: Optional. Id of the existing Internet Gateway.
  If not set, create a new Internet Gateway.

*NOTE: if you are planning to run the monitoring stack, set the
`CLUSTER_DESIRED_CAPACITY` value to at least 2. The resources provided by
a single EC2 instance won't be enough for all the services that will be ran*

### Prerequisites

As a prerequisite to run this stack, you will need:
* a registered and correctly configured domain in
[Route53](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/getting-started.html)
* to [publish the Docker image](#publish-custom-gerrit-docker-image) with your
Gerrit configuration in AWS ECR
* to [publish the SSH Agent Docker image](#publish-ssh-agent) in AWS ECR
* to [publish the Git Daemon Docker image](#publish-git-daemon) in AWS ECR
* to [add Gerrit secrets](#add-gerrit-secrets-in-aws-secret-manager) in AWS Secret
Manager
* an SSL Certificate in AWS Certificate Manager (you can find more information on
  how to create and handle certificates in AWS [here](https://aws.amazon.com/certificate-manager/getting-started/)

### Add Gerrit Secrets in AWS Secret Manager

[AWS Secret Manager](https://aws.amazon.com/secrets-manager/) is a secure way of
storing and managing secrets of any type.

The secrets you will have to add are the Gerrit SSH keys and the Register Email
Private Key set in `secure.config`.

#### SSH Keys

The SSH keys you will need to add are the one usually created and used by Gerrit:
* ssh_host_ecdsa_384_key
* ssh_host_ecdsa_384_key.pub
* ssh_host_ecdsa_521_key
* ssh_host_ecdsa_521_key.pub
* ssh_host_ecdsa_key
* ssh_host_ecdsa_key.pub
* ssh_host_ed25519_key
* ssh_host_ed25519_key.pub
* ssh_host_rsa_key
* ssh_host_rsa_key.pub

Plus a key used by the replication plugin:
* replication_user_id_rsa
* replication_user_id_rsa.pub

Generate a random bearer token to be used for monitoring with Promtetheus:
* `openssl rand -hex 20 > prometheus_bearer_token`

You will have to create the keys and place them in a directory.

#### Register Email Private Key

You will need to create a secret and put it in a file called `registerEmailPrivateKey`
in the same directory of the SSH keys.

#### LDAP Password

You will need to put the admin LDAP password in a file called `ldapPassword`
in the same directory of the SSH keys.

#### SMTP Password

You will need to put the SMTP password in a file called `smtpPassword`
in the same directory of the SSH keys.

#### Import into AWS Secret Manager

You can now run the [script](../gerrit/add_secrets_aws_secrets_manager.sh) to
upload them to AWS Secret Manager:
`add_secrets_aws_secrets_manager.sh /path/to/your/keys/directory secret_prefix aws-region-id`

When `secret_prefix` is omitted, it is set to `gerrit_secret` by default.

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

### Publish SSH Agent

* Create the repository in the Docker registry:
  `aws ecr create-repository --repository-name aws-gerrit/git-ssh`
* Publish the image: `make git-ssh-publish`

### Publish Git Daemon

* Create the repository in the Docker registry:
  `aws ecr create-repository --repository-name aws-gerrit/git-daemon`
* Publish the image: `make git-daemon-publish`

### Getting Started

* Create the cluster, services and DNS routing stacks:

```
make create-all
```

The slave will start with 5 min delay to allow the replication from master of `All-Users`
and `All-Projects` to happen.
You can now check in the slave logs to see when the slave is up and running.

*NOTE: the creation of the cluster needs an EC2 key pair are useful when you need to connect
to the EC2 instances for troubleshooting purposes. The key pair is automatically generated
and store them in a `pem` file on the current directory.
To use when ssh-ing into your instances as follow: `ssh -i cluster-keys.pem ec2-user@<ec2_instance_ip>`*

### Cleaning up

```
make delete-all
```

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

## Monitoring

If you want to monitor your system, you can add a Prometheus and Grafana stack.
[Here](../monitoring/README.md) you can find the details on how to add it.

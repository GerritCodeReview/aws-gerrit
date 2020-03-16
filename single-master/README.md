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
* `CLUSTER_STACK_NAME`: Optional. Name of the cluster stack. `gerrit-cluster` by default.
* `SERVICE_STACK_NAME`: Optional. Name of the service stack. `gerrit-service` by default.
* `DNS_ROUTING_STACK_NAME`: Optional. Name of the DNS routing stack. `gerrit-dns-routing` by default.
* `HOSTED_ZONE_NAME`: Optional. Name of the hosted zone. `mycompany.com` by default.
* `SUBDOMAIN`: Optional. Name of the sub domain. `gerrit-master-demo` by default.

### Prerequisites

As a prerequisite to run this stack, you will need:
* a registered and correctly configured domain in
[Route53](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/getting-started.html)
* to [publish the Docker image](#publish-custom-gerrit-docker-image) with your
Gerrit configuration
* to [add Gerrit secrets](#add-gerrit-secrets-in-aws-secret-manager) in AWS Secret
Manager

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

You will have to create the keys and place them in a directory.

#### Register Email Private Key

You will need to create a secret and put it in a file called `registerEmailPrivateKey`
in the same directory of the SSH keys.

#### Import into AWS Secret Manager

You can now run the script to upload them to AWS Secret Manager:
`add_secrets_aws_secrets_manager.sh /path/to/your/keys/directory`

### Publish custom Gerrit Docker image

* Create the repository in the Docker registry:
  `aws ecr create-repository --repository-name aws-gerrit/gerrit`
* Set the Docker registry URI in `DOCKER_REGISTRY_URI`
* Adjust the `gerrit.config` in `./gerrit/etc`
* Add the plugins you want to install in `./gerrit/plugins`
* Publish the image: `make gerrit-publish`

### Getting Started

* Create a key pair to access the EC2 instances in the cluster:

```
aws ec2 create-key-pair --key-name gerrit-cluster-keys \
  --query 'KeyMaterial' --output text > gerrit-cluster.pem
```

*NOTE: the EC2 key pair are useful when you need to connect to the EC2 instances
for troubleshooting purposes. Store them in a `pem` file to use when ssh-ing into your
instances as follow: `ssh -i yourKeyPairs.pem <ec2_instance_ip>`*

* Create the cluster, service and DNS routing stacks:

```
make create-all
```

### Cleaning up

```
make delete-all
```

### Access your Gerrit

You Gerrit instance will be available at this URL: `http://<HOSTED_ZONE_NAME>.<SUBDOMAIN>`.

The available ports are `8080` for HTTP and `29418` for SSH.

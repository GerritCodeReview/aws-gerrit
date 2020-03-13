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

### Deployment type

* Latest Gerrit version deployed using the official [Docker image](https://hub.docker.com/r/gerritcodereview/gerrit)
* Application deployed in ECS on a single EC2 instance

### Logging

* Gerrit `error_log` is exported in a Log Group in CloudWatch
* Other Gerrit logs still need to be exported

### Monitoring

* Standard CloudWatch monitoring metrics for each component

## How to run it

### Getting Started

As a prerequisite to run this stack, you will need a registered and correctly
configured domain in [Route53](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/getting-started.html).

Once you will have it you can continue with the next steps:

* Create a key pair to access the EC2 instances in the cluster:

```
aws ec2 create-key-pair --key-name gerrit-cluster-keys
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

### Stack parameters

The above commands for the creation and deletion of the stacks use a set of default
parameters which can be overridden as in the following example:

```
make create-all CLUSTER_STACK_NAME=my-cluster-stack SERVICE_STACK_NAME=my-service-stack
```

Keep in mind, that once you override a parameter in the creation of the stack,
you will have to do the same in the deletion, i.e.:

```
make delete-all CLUSTER_STACK_NAME=my-cluster-stack SERVICE_STACK_NAME=my-service-stack
```

This is the list of the parameters:

* `CLUSTER_STACK_NAME`: name of the cluster stack. `gerrit-cluster` by default.
* `SERVICE_STACK_NAME`: name of the service stack. `gerrit-service` by default.
* `DNS_ROUTING_STACK_NAME`: name of the DNS routing stack. `gerrit-dns-routing` by default.
* `HOSTED_ZONE_NAME`: name of the hosted zone. `mycompany.com` by default.
* `SUBDOMAIN`: name of the sub domain. `gerrit-master-demo` by default.

### Access your Gerrit

You Gerrit instance will be available at this URL: `http://<HOSTED_ZONE_NAME>.<SUBDOMAIN>`.

The available ports are `8080` for HTTP and `29418` for SSH.

# Gerrit Single Master

This set of Templates provide all the components to deploy a single Gerrit master
in ECS

## Architecture

Two templates are provided in this example:
* `cf-cluster`: define the ECS cluster and the networking stack
* `cf-service`: defined the service stack running Gerrit

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

* Create a key pair to access the EC2 instances in the cluster:

```
aws ec2 create-key-pair --key-name gerrit-cluster-keys
```

*NOTE: the EC2 key pair are useful when you need to connect to the EC2 instances
for troubleshooting purposes. Store them in a `pem` file to use when ssh-ing into your
instances as follow: `ssh -i yourKeyPairs.pem <ec2_instance_ip>`*

* Create the cluster and service stack:

```
make create-all
```

By default the cluster and service name are called, respectively, `cluster-stack`
and `service-stack`. If you want to change the name you can do it by overriding
the *Makefile* parameters:

```
make create-all CLUSTER_STACK_NAME=my-cluster-stack SERVICE_STACK_NAME=my-service-stack
```

Keep in mind you will have to pass the same parameters when deleting the stacks.

### Cleaning up

```
make delete-all
```

### Access your Gerrit

You can find the Gerrit public URL by running the following command:

```
aws cloudformation describe-stacks --stack-name gerrit-service
```

In the `Outputs` section the URL is set in the `PublicLoadBalancerUrl` key:

```
  "Outputs": [
    {
      "OutputKey": "PublicLoadBalancerUrl",
      "OutputValue": "http://gerri-LoadB-1CDG276QVT8K8-e28c5bca2e024135.elb.us-east-2.amazonaws.com",
      "Description": "The url of the external load balancer",
      "ExportName": "gerrit-ponch-service:PublicLoadBalancerUrl"
    }
  ],
```

The available ports are `8080` for HTTP and `29418` for SSH

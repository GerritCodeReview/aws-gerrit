# LDAP

This is a set of Cloud Formation Templates and scripts to spin up a simple LDAP
service and its Admin panel.

It can be used to provide a simple LDAP instance to be used to integrate with
any Gerrit setup in the different cookbooks.

## How to run it

### Prerequisites

As a prerequisite to run this stack, you will need a registered and correctly
configured domain in [Route53](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/getting-started.html)

### Getting Started

* Create a key pair to access the EC2 instances in the cluster:

```
aws ec2 create-key-pair --key-name gerrit-cluster-keys \
  --query 'KeyMaterial' --output text > gerrit-cluster.pem
```

*NOTE: the EC2 key pair are useful when you need to connect to the EC2 instances
for troubleshooting purposes. Store them in a `pem` file to use when ssh-ing into your
instances as follow: `ssh -i yourKeyPairs.pem <ec2_instance_ip>`*

* Create the LDAP stack:

```
make ldap HOSTED_ZONE_NAME=mycompany.com
```

The `HOSTED_ZONE_NAME` value is the Hosted Zone Name where a DSN route pointing
to the LDAP service will be created.

### Cleaning up

```
make delete-ldap
```

### Access your LDAP instance

* LDAP Service:
 * **URI**: ldap://gerrit-ldap.gerritforgeaws.com
 * **Port**: 636
* LDAP Admin Service:
 * **URI**: https://gerrit-ldap.mycompany.com
 * **Port**: 6443
 * **Username**: cn=admin,dc=example,dc=org
 * **Password**: secret

The LDAP instance provided already has a Gerrit Admin user baked in with the
following credentials:

* **Username**: gerritadmin
* **Password**: secret

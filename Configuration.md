# Configuration

Each recipe provides a `setup.env.template` file which is a template for configuring the Gerrit stacks.
Copy that into a `setup.env` and set the correct values for the  provided environment variables.

```bash
cp setup.env.template setup.env
```
Here below a list of variables that are common and need to be specified regardless the recipe you want to
deploy. Please refer to the individual recipes to understand what additional variables need to be set.

## Common parameters

#### Environment

Configuration values affecting deployment environment and cluster properties

* `AWS_REGION`: Optional. Which region to deploy to. `us-east-1` by default.
* `AWS_PREFIX`: Optional. A string to prefix stacks and resources with. `gerrit` by default.
* `DOCKER_REGISTRY_URI`: Mandatory. URI of the Docker registry. See the
  [prerequisites](Prerequisites.md) section for more details.
* `SSL_CERTIFICATE_ARN`: Mandatory. ARN of the wildcard SSL Certificate, covering both master nodes.
* `CLUSTER_STACK_NAME`: Optional. Name of the cluster stack. `gerrit-cluster` by default.
* `DNS_ROUTING_STACK_NAME`: Optional. Name of the DNS routing stack. `gerrit-dns-routing` by default.
* `HOSTED_ZONE_NAME`: Optional. Name of the hosted zone. `mycompany.com` by default.
* `GERRIT_KEY_PREFIX` : Optional. Secrets prefix used during the [Import into AWS Secret Manager](#import-into-aws-secret-manager).
  `gerrit_secret` by default.

#### SPECS

Configuration values to spec up Gerrit containers.

* `CLUSTER_INSTANCE_TYPE`: Optional. The EC2 instance Type used to run the cluster. The default value
is recipe-specific:
  * single-master: `m4.large`
  * master-slave: `m4.xlarge`
  * dual-master: `m4.2xlarge`
* `GERRIT_RAM`: RAM allocated (MiB) to the Gerrit container. `6000` by default.
* `GERRIT_CPU`: vCPU units allocated to the Gerrit container. `1024` by default.
* `GERRIT_HEAP_LIMIT`: Maximum heap size of the Java process running Gerrit, in bytes.
  See [Gerrit documentation](https://gerrit-review.googlesource.com/Documentation/config-gerrit.html#container.heapLimit)
  `6g` by default.
* `JGIT_CACHE_SIZE`: Maximum number of bytes to load and cache in memory from pack files.
  See [Gerrit documentation](https://gerrit-review.googlesource.com/Documentation/config-gerrit.html#core.packedGitLimit)
  for more details. `3g` by default.
* `INTERNET_GATEWAY_ID`: Optional. Id of the existing Internet Gateway.
  If not set, create a new Internet Gateway
* `VPC_ID`: Optional. Id of the existing VPC.
  If not set, create a new VPC.
* `VPC_CIDR`: Optional. CIDR mask for the VPC.
  `10.0.0.0/16` by default.
* `SUBNET_ID`: Optional. Id of the existing Subnet.
  If not set, create a new Network Stack.
* `SUBNET_CIDR`: Optional. CIDR mask of the Subnet.
  `10.0.0.0/24` by default.
* LOAD_BALANCER_SCHEME: Optional. The Load Balancer scheme type. `internet-facing` by default.
  Allowed values: internal, internet-facing
* `GERRIT_VOLUME_ID` : Optional. Id of extisting EBS volume. If empty new volume for Gerrit data will
be created
* `GERRIT_VOLUME_SNAPSHOT_ID` : Optional. Ignored if GERRIT_VOLUME_ID is not empty. Id of the EBS volume
snapshot used to create new EBS volume for Gerrit data.

#### CloudWatch Monitoring

Application level metrics for CloudWatch are available through the
[metrics-reporter-cloudwatch](https://gerrit.googlesource.com/plugins/metrics-reporter-cloudwatch/)
plugin.

* `METRICS_CLOUDWATCH_ENABLED`: Optional - Boolean.
Whether to publish metrics to CloudWatch and create CloudWatch dashboard. Default: false
* `METRICS_CLOUDWATCH_NAMESPACE`: Optional - String.
The CloudWatch namespace for Gerrit metrics. Default: _gerrit_
* `METRICS_CLOUDWATCH_RATE`: Optional - String.
The rate at which metrics should be fired to AWS. Default: _60s_
* `METRICS_CLOUDWATCH_INITIAL_DELAY`: Optional - String.
The time to delay the first reporting execution. Default: _0_
* `METRICS_CLOUDWATCH_JVM_ENABLED`: Optional - Boolean.
Publish JVM metrics. Default: _false_
* `METRICS_CLOUDWATCH_DRY_RUN`: Optional - Boolean.
Log.DEBUG the metrics, rather than publishing. Default: _false_
* `METRICS_CLOUDWATCH_EXCLUDE_METRICS_LIST`: Optional. Comma-separated list.
 Regex patterns to exclude from publishing. Default: empty string.

#### LDAP

Configuration values related to LDAP integration.
See more details [here](https://gerrit-review.googlesource.com/Documentation/config-gerrit.html#ldap)

* `LDAP_SERVER`: Mandatory. URL of the organization’s LDAP server to query for user information and group membership from
  See [Gerrit documentation](https://gerrit-review.googlesource.com/Documentation/config-gerrit.html#ldap.server)
* `LDAP_USERNAME`: Mandatory. Username to bind to the LDAP server with
  See [Gerrit documentation](https://gerrit-review.googlesource.com/Documentation/config-gerrit.html#ldap.username)
* `LDAP_ACCOUNT_BASE`: Mandatory. Root of the tree containing all user accounts
  See [Gerrit documentation](https://gerrit-review.googlesource.com/Documentation/config-gerrit.html#ldap.accountBase)
* `LDAP_GROUP_BASE`: Mandatory. Root of the tree containing all group objects
  See [Gerrit documentation](https://gerrit-review.googlesource.com/Documentation/config-gerrit.html#ldap.groupBase)
* `LDAP_ACCOUNT_PATTERN`: Optional. Query pattern to use when searching for a user account. If parameters is
   setup in setup.env configuration file, '$' needs to be escaped with '$$$$', for example (&(objectClass=person)(uid=$$$${username}))
  See [Gerrit documentation](https://gerrit-review.googlesource.com/Documentation/config-gerrit.html#ldap.accountPattern)
  Default: (&(objectClass=person)(uid=$$$${username}))

#### SMTP

Configuration values related to SMTP integration.
See more details [here](https://gerrit-review.googlesource.com/Documentation/config-gerrit.html#sendemail)

* `SMTP_SERVER`: Mandatory. Hostname (or IP address) of a SMTP server that will relay messages generated by Gerrit to end users
  See [Gerrit documentation](https://gerrit-review.googlesource.com/Documentation/config-gerrit.html#sendemail.smtpServer)
* `SMTP_SERVER_PORT`: Optional. Port number of the SMTP server.
  See [Gerrit documentation](https://gerrit-review.googlesource.com/Documentation/config-gerrit.html#sendemail.smtpServerPort)
  Default: 465
* `SMTP_USER`: Mandatory. User name to authenticate with
  See [Gerrit documentation](https://gerrit-review.googlesource.com/Documentation/config-gerrit.html#sendemail.smtpUser)
* `SMTP_DOMAIN`: Mandatory. Domain to be used in the "From" field of any generated email messages
  See [Gerrit documentation](https://gerrit-review.googlesource.com/Documentation/config-gerrit.html#sendemail.from)
* SMTP_ENCRYPTION : Optional. Specify the encryption to use, either 'ssl', 'tls' or 'none'
  See [Gerrit documentation](https://gerrit-review.googlesource.com/Documentation/config-gerrit.html#sendemail.smtpEncryption)
  Default: ssl
* SMTP_SSL_VERIFY: Optional. If false and SMTP_ENCRYPTION is 'ssl' or 'tls', Gerrit will not verify the server certificate
   when it connects to send an email message.
  See [Gerrit documentation](https://gerrit-review.googlesource.com/Documentation/config-gerrit.html#sendemail.sslVerify)
  Default: false


# Geo Location Routing

This recipe lets you define a DNS configuration to two different Gerrit sites,
deployed in AWS, so that the traffic routed to a specific site based on the
location of the users. 

It is based on the Route53's GeoLocation routing strategy (docs can be found
[here](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/routing-policy.html#routing-policy-geo))

## How to run it

### Prerequisites

This recipe assumes that you do have a multi-site Gerrit deployment in two regions.
You can refer to the [relevant documentation](../dual-master/README.md#multi-site)
to understand how to setup Gerrit in a multi-site deployment. 

### Configuration

* `GEO_LOCATION_ROUTING_STACK_NAME`: Required. The name of the cloudformation stack
* created by this recipe.

* `HOSTED_ZONE_NAME`: Required. The name of the DNS zone name that will host the
geo-location entries.

* `HOSTED_ZONE_ID`: Required. The Id of the route53 zone that will host the
geo-location entries. You can find this value by navigating to the relevant zone
via the Route53 control panel. Alternatively you can inspect it by issuing

```shell script
aws route53 list-hosted-zones
```

* `GLOBAL_SUBDOMAIN_NAME`: Required. The subdomain for the record that will
perform the geo-location-based routing. This will be used together with the
`HOSTED_ZONE_NAME` to define a fqdn. Specifying `global.gerrit-demo` for example
will generate an entry `global.gerrit-demo.yourcompany.com`

* `SITE_A_CONTINENT_CODE`: Required. Traffic coming from this continent will be
routed to the `SITE_A_ALIAS_TARGET`. Allowed values are:
('AF', 'AN', 'AS', 'EU', 'OC', 'NA', 'SA'). For more details on this please check
the [AWS documentation](https://docs.aws.amazon.com/Route53/latest/APIReference/API_GetGeoLocation.html#API_GetGeoLocation_RequestSyntax) 

* `SITE_A_ALIAS_TARGET`: Required. Gerrit site to route traffic to, when it originates
from `SITE_A_CONTINENT_CODE`

* `SITE_B_CONTINENT_CODE`: Required. Traffic coming from this continent will be
routed to the `SITE_A_ALIAS_TARGET`. Allowed values are:
('AF', 'AN', 'AS', 'EU', 'OC', 'NA', 'SA'). For more details on this please check
the [AWS documentation](https://docs.aws.amazon.com/Route53/latest/APIReference/API_GetGeoLocation.html#API_GetGeoLocation_RequestSyntax) 

* `SITE_B_ALIAS_TARGET`: Required. Gerrit site to route traffic to, when it originates
from `SITE_B_CONTINENT_CODE`

* `DEFAULT_ALIAS_TARGET`: Required. Gerrit site to route traffic to when it doesn't
originate from `SITE_A_CONTINENT_CODE` nor `SITE_A_CONTINENT_CODE`

### Healthcheck

In addition to the DNS records, two healthchecks will also be created: one to
monitor `SITE_A_ALIAS_TARGET` and one to monitor `SITE_B_ALIAS_TARGET` respectively.

The healthcheck polls the healthcheck endpoint exposed by the gerrit target, over
HTTPS, as such:

```
https://SITE_A_ALIAS_TARGET/config/server/healthcheck~status
```

Should one of the two healthcheck become unhealthy, the traffic will be routed
to the healthy one. 

### Deploy

```
make [AWS_REGION=a-valid-aws-region] [AWS_PREFIX=some-cluster-prefix] create-all
```

The optional `AWS_REGION` and `AWS_REFIX` allow you to define where it will be deployed and what it will be named.

It might take several minutes to build the stack.
You can monitor the creations of the stacks in [CloudFormation](https://console.aws.amazon.com/cloudformation/home)

### Cleaning up

```
make [AWS_REGION=a-valid-aws-region] [AWS_PREFIX=some-cluster-prefix] delete-all
```

The optional `AWS_REGION` and `AWS_REFIX` allow you to specify exactly which stack you target for deletion.

### Limitations

* Only support two sites at the moment.
* Only support mapping of *one* location to *one* target. All other traffic will
be routed to the default target.
* The healthcheck request interval is hardcoded to be every "30 secs" and the failure
threshold is set to "3"
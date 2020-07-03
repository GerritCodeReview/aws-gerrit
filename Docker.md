# Docker Operations

The templates provided by this repo aim to deploy Gerrit (and the relevant infrastructure) as containerized
applications over Amazon ECS. In order to achieve this the application components, including Gerrit are packaged
as docker images and stored in ECR, the AWS docker registry.

## Configure Elastic Container Registry (ECR)

Set the `DOCKER_REGISTRY_URI` environment variable in your `setup.env` file. This will be

```bash
<aws_account_id>.dkr.ecr.<aws_region>.amazonaws.com
```

The existence of the docker repositories is left as a prerequisite manual step,
see [documentation](Prerequisites.md)

## Publishing Docker images

The Makefiles provided by these recipes allow to publish docker images to ECR (see below).
You might want to do this to test building phase without deploying a new cluster, however you should keep in mind that
publishing a new docker image will _not_ make it available to ECS, so it cannot be used for upgrading running instances.

Note that you will need to _cd_ to the recipe directory before running any of the following and that the relevant image
needs to exist for that specific recipe (for example you can't publish HAProxy from the single-master recipe).

* Gerrit: `make gerrit-publish`
* SSH Agent: `make git-ssh-publish`
* Gerrit Daemon: `make git-daemon-publish`
* Grafana: `make grafana-publish`
* Prometheus: `make prometheus-publish`
* HAProxy: `make haproxy-publish`
* Syslog sidecar: `make syslog-sidecar-publish`






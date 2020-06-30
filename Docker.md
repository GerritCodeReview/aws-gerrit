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


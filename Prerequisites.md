# Prerequisites

Before configuring, setting up and deploying a gerrit stack on AWS, there are some one-off operations
that are required. These includes key creations, certificates, docker registries etc.
The prerequisites to run this stack are:

* a registered and correctly configured domain in
[Route53](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/getting-started.html)

* Make sure ECR repositories exist

```bash
aws ecr create-repository --repository-name aws-gerrit/gerrit
aws ecr create-repository --repository-name aws-gerrit/git-ssh
aws ecr create-repository --repository-name aws-gerrit/git-daemon
aws ecr create-repository --repository-name aws-gerrit/haproxy
aws ecr create-repository --repository-name aws-gerrit/syslog-sidecar
aws ecr create-repository --repository-name aws-gerrit/prometheus
aws ecr create-repository --repository-name aws-gerrit/grafana
```

* to upload required secrets to AWS Secret Manager. You can follow the steps [here](Secrets.md))

* an SSL Certificate in AWS Certificate Manager (you can find more information on
  how to create and handle certificates in AWS [here](https://aws.amazon.com/certificate-manager/getting-started/)

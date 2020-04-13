include ../$(RECIPE)/setup.env

AWS_FC_COMMAND=export AWS_PAGER=;aws cloudformation
SERVICE_PROMETHEUS_TEMPLATE:=cf-service-prometheus.yml

service-monitoring: service-prometheus service-grafana

service-prometheus:
	@echo "Create Prometheus stack"
	$(AWS_FC_COMMAND) create-stack \
		--stack-name $(SERVICE_PROMETHEUS_STACK_NAME) \
		--capabilities CAPABILITY_IAM  \
		--template-body file://`pwd`/$(SERVICE_PROMETHEUS_TEMPLATE) \
		--region $(AWS_REGION) \
		--parameters \
		ParameterKey=ClusterStackName,ParameterValue=$(CLUSTER_STACK_NAME) \
		ParameterKey=HostedZoneName,ParameterValue=$(HOSTED_ZONE_NAME) \
		ParameterKey=Subdomain,ParameterValue=$(PROMETHEUS_SUBDOMAIN) \
		ParameterKey=DockerRegistryUrl,ParameterValue=$(DOCKER_REGISTRY_URI) \
		ParameterKey=CertificateArn,ParameterValue=$(SSL_CERTIFICATE_ARN)


service-grafana:
	@echo "Create Grafana stack"

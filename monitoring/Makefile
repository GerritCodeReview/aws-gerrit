include ../$(RECIPE)/setup.env

AWS_FC_COMMAND=export AWS_PAGER=;aws cloudformation
SERVICE_PROMETHEUS_TEMPLATE:=cf-service-prometheus.yml
SERVICE_GRAFANA_TEMPLATE:=cf-service-grafana.yml
DNS_ROUTING_MONITORING_TEMPLATE:=cf-dns-route.yml

service-monitoring: service-prometheus wait-for-service-prometheus-creation \
										service-grafana wait-for-service-grafana-creation \
										dns-monitoring-routing wait-for-dns-routing-creation

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
		ParameterKey=CertificateArn,ParameterValue=$(SSL_CERTIFICATE_ARN) \
		ParameterKey=TokenVersion,ParameterValue=$(TOKEN_VERSION)

service-grafana:
	@echo "Create Grafana stack"
	$(AWS_FC_COMMAND) create-stack \
		--stack-name $(SERVICE_GRAFANA_STACK_NAME) \
		--capabilities CAPABILITY_IAM  \
		--template-body file://`pwd`/$(SERVICE_GRAFANA_TEMPLATE) \
		--region $(AWS_REGION) \
		--parameters \
		ParameterKey=ClusterStackName,ParameterValue=$(CLUSTER_STACK_NAME) \
		ParameterKey=PrometheusStackName,ParameterValue=$(SERVICE_PROMETHEUS_STACK_NAME) \
		ParameterKey=HostedZoneName,ParameterValue=$(HOSTED_ZONE_NAME) \
		ParameterKey=Subdomain,ParameterValue=$(GRAFANA_SUBDOMAIN) \
		ParameterKey=DockerRegistryUrl,ParameterValue=$(DOCKER_REGISTRY_URI) \
		ParameterKey=CertificateArn,ParameterValue=$(SSL_CERTIFICATE_ARN)

dns-monitoring-routing:
	$(AWS_FC_COMMAND) create-stack \
		--stack-name $(DNS_ROUTING_MONITORING_STACK_NAME) \
		--capabilities CAPABILITY_IAM  \
		--template-body file://`pwd`/$(DNS_ROUTING_MONITORING_TEMPLATE) \
		--region $(AWS_REGION) \
		--parameters \
		ParameterKey=PrometheusServiceStackName,ParameterValue=$(SERVICE_PROMETHEUS_STACK_NAME) \
		ParameterKey=GrafanaServiceStackName,ParameterValue=$(SERVICE_GRAFANA_STACK_NAME)

wait-for-service-prometheus-creation:
	@echo "*** Wait for Serice Prometheus stack '$(SERVICE_PROMETHEUS_STACK_NAME)' creation"
	$(AWS_FC_COMMAND) wait stack-create-complete \
	--stack-name $(SERVICE_PROMETHEUS_STACK_NAME) \
	--region $(AWS_REGION)
	@echo "*** Serice Prometheus stack '$(SERVICE_PROMETHEUS_STACK_NAME)' created"

wait-for-service-grafana-creation:
	@echo "*** Wait for Serice Grafana stack '$(SERVICE_GRAFANA_STACK_NAME)' creation"
	$(AWS_FC_COMMAND) wait stack-create-complete \
	--stack-name $(SERVICE_GRAFANA_STACK_NAME) \
	--region $(AWS_REGION)
	@echo "*** Serice Prometheus stack '$(SERVICE_GRAFANA_STACK_NAME)' created"

wait-for-dns-routing-creation:
	@echo "*** Wait for DNS routing stack '$(DNS_ROUTING_MONITORING_STACK_NAME)' creation"
	$(AWS_FC_COMMAND) wait stack-create-complete \
	--stack-name $(DNS_ROUTING_MONITORING_STACK_NAME) \
	--region $(AWS_REGION)
	@echo "*** DNS Routing stack '$(DNS_ROUTING_MONITORING_STACK_NAME)' created"

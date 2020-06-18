include ../Makefile.common
include setup.env

CLUSTER_TEMPLATE:=cf-cluster.yml
SERVICE_MASTER_TEMPLATE:=cf-service-master.yml
SERVICE_SLAVE_TEMPLATE:=cf-service-slave.yml
DNS_ROUTING_TEMPLATE:=cf-dns-route.yml
AWS_FC_COMMAND=export AWS_PAGER=;aws cloudformation

.PHONY: create-all delete-all \
				cluster cluster-keys service-master service-slave dns-routing \
				delete-cluster delete-service-master delete-service-slave delete-dns-routing \
				wait-for-cluster-creation wait-for-service-master-creation wait-for-dns-routing-creation \
				wait-for-cluster-deletion wait-for-service-master-deletion wait-for-dns-routing-deletion \
				gerrit-build gerrit-publish

create-all: upload-common-templates \
						gerrit-publish git-daemon-publish git-ssh-publish \
						cluster wait-for-cluster-creation \
						service-slave service-master \
						wait-for-service-master-creation wait-for-service-slave-creation \
						dns-routing wait-for-dns-routing-creation

cluster: cluster-keys
	$(AWS_FC_COMMAND) create-stack \
		--stack-name $(CLUSTER_STACK_NAME) \
		--capabilities CAPABILITY_IAM  \
		--template-body file://`pwd`/$(CLUSTER_TEMPLATE) \
		--region $(AWS_REGION) \
		--parameters \
		ParameterKey=DesiredCapacity,ParameterValue=$(CLUSTER_DESIRED_CAPACITY) \
		ParameterKey=ECSKeyName,ParameterValue=$(CLUSTER_KEYS)

service-master:
	$(AWS_FC_COMMAND) create-stack \
		--stack-name $(SERVICE_MASTER_STACK_NAME) \
		--capabilities CAPABILITY_IAM  \
		--template-body file://`pwd`/$(SERVICE_MASTER_TEMPLATE) \
		--region $(AWS_REGION) \
		--parameters \
		ParameterKey=ClusterStackName,ParameterValue=$(CLUSTER_STACK_NAME) \
		ParameterKey=HostedZoneName,ParameterValue=$(HOSTED_ZONE_NAME) \
		ParameterKey=Subdomain,ParameterValue=$(MASTER_SUBDOMAIN) \
		ParameterKey=DockerRegistryUrl,ParameterValue=$(DOCKER_REGISTRY_URI) \
		ParameterKey=CertificateArn,ParameterValue=$(SSL_CERTIFICATE_ARN) \
		ParameterKey=SlaveServiceStackName,ParameterValue=$(SERVICE_SLAVE_STACK_NAME) \
		ParameterKey=GerritKeyPrefix,ParameterValue=$(GERRIT_KEY_PREFIX)\
		ParameterKey=DockerImage,ParameterValue=aws-gerrit/gerrit:$(IMAGE_TAG) \
		ParameterKey=GerritRAM,ParameterValue=$(GERRIT_RAM) \
		ParameterKey=GerritCPU,ParameterValue=$(GERRIT_CPU)

service-slave:
	$(AWS_FC_COMMAND) create-stack \
		--stack-name $(SERVICE_SLAVE_STACK_NAME) \
		--capabilities CAPABILITY_IAM  \
		--template-body file://`pwd`/$(SERVICE_SLAVE_TEMPLATE) \
		--region $(AWS_REGION) \
		--parameters \
		ParameterKey=ClusterStackName,ParameterValue=$(CLUSTER_STACK_NAME) \
		ParameterKey=HostedZoneName,ParameterValue=$(HOSTED_ZONE_NAME) \
		ParameterKey=Subdomain,ParameterValue=$(SLAVE_SUBDOMAIN) \
		ParameterKey=DockerRegistryUrl,ParameterValue=$(DOCKER_REGISTRY_URI) \
		ParameterKey=CertificateArn,ParameterValue=$(SSL_CERTIFICATE_ARN) \
		ParameterKey=GerritKeyPrefix,ParameterValue=$(GERRIT_KEY_PREFIX)\
		ParameterKey=GerritDockerImage,ParameterValue=aws-gerrit/gerrit:$(IMAGE_TAG) \
		ParameterKey=GerritRAM,ParameterValue=$(GERRIT_RAM) \
		ParameterKey=GerritCPU,ParameterValue=$(GERRIT_CPU)

dns-routing:
	$(AWS_FC_COMMAND) create-stack \
		--stack-name $(DNS_ROUTING_STACK_NAME) \
		--capabilities CAPABILITY_IAM  \
		--template-body file://`pwd`/$(DNS_ROUTING_TEMPLATE) \
		--region $(AWS_REGION) \
		--parameters \
		ParameterKey=MasterServiceStackName,ParameterValue=$(SERVICE_MASTER_STACK_NAME) \
		ParameterKey=SlaveServiceStackName,ParameterValue=$(SERVICE_SLAVE_STACK_NAME)

wait-for-cluster-creation:
	@echo "*** Wait for cluster stack '$(CLUSTER_STACK_NAME)' creation"
	$(AWS_FC_COMMAND) wait stack-create-complete \
	--stack-name $(CLUSTER_STACK_NAME) \
	--region $(AWS_REGION)
	@echo "*** Cluster stack '$(CLUSTER_STACK_NAME)' created"

wait-for-service-master-creation:
	@echo "*** Wait for service master stack '$(SERVICE_MASTER_STACK_NAME)' creation"
	$(AWS_FC_COMMAND) wait stack-create-complete \
	--stack-name $(SERVICE_MASTER_STACK_NAME) \
	--region $(AWS_REGION)
	@echo "*** Service stack '$(SERVICE_MASTER_STACK_NAME)' created"

wait-for-service-slave-creation:
	@echo "*** Wait for service slave stack '$(SERVICE_SLAVE_STACK_NAME)' creation"
	$(AWS_FC_COMMAND) wait stack-create-complete \
	--stack-name $(SERVICE_SLAVE_STACK_NAME) \
	--region $(AWS_REGION)
	@echo "*** Service stack '$(SERVICE_SLAVE_STACK_NAME)' created"

wait-for-dns-routing-creation:
	@echo "*** Wait for DNS routing stack '$(DNS_ROUTING_STACK_NAME)' creation"
	$(AWS_FC_COMMAND) wait stack-create-complete \
	--stack-name $(DNS_ROUTING_STACK_NAME) \
	--region $(AWS_REGION)
	@echo "*** DNS Routing stack '$(DNS_ROUTING_STACK_NAME)' created"

wait-for-cluster-deletion:
	@echo "*** Wait for cluster stack '$(CLUSTER_STACK_NAME)' deletion"
	$(AWS_FC_COMMAND) wait stack-delete-complete \
	--stack-name $(CLUSTER_STACK_NAME) \
	--region $(AWS_REGION)
	@echo "*** Cluster stack '$(CLUSTER_STACK_NAME)' deleted"

wait-for-service-master-deletion:
	@echo "*** Wait for service master stack '$(SERVICE_MASTER_STACK_NAME)' deletion"
	$(AWS_FC_COMMAND) wait stack-delete-complete \
	--stack-name $(SERVICE_MASTER_STACK_NAME) \
	--region $(AWS_REGION)
	@echo "*** Service stack master '$(SERVICE_MASTER_STACK_NAME)' deleted"

wait-for-service-slave-deletion:
	@echo "*** Wait for service master stack '$(SERVICE_SLAVE_STACK_NAME)' deletion"
	$(AWS_FC_COMMAND) wait stack-delete-complete \
	--stack-name $(SERVICE_SLAVE_STACK_NAME) \
	--region $(AWS_REGION)
	@echo "*** Service stack master '$(SERVICE_SLAVE_STACK_NAME)' deleted"

wait-for-dns-routing-deletion:
	@echo "*** Wait for DNS routing stack '$(DNS_ROUTING_STACK_NAME)' deletion"
	$(AWS_FC_COMMAND) wait stack-delete-complete \
	--stack-name $(DNS_ROUTING_STACK_NAME) \
	--region $(AWS_REGION)
	@echo "*** DNS routing stack '$(DNS_ROUTING_STACK_NAME)' deleted"

delete-cluster:
	$(AWS_FC_COMMAND) delete-stack \
	--stack-name $(CLUSTER_STACK_NAME) \
	--region $(AWS_REGION)

delete-service-master:
	$(AWS_FC_COMMAND) delete-stack \
	--stack-name $(SERVICE_MASTER_STACK_NAME) \
	--region $(AWS_REGION)

delete-service-slave:
	$(AWS_FC_COMMAND) delete-stack \
	--stack-name $(SERVICE_SLAVE_STACK_NAME) \
	--region $(AWS_REGION)

delete-dns-routing:
	$(AWS_FC_COMMAND) delete-stack \
	--stack-name $(DNS_ROUTING_STACK_NAME) \
	--region $(AWS_REGION)

delete-all: delete-dns-routing wait-for-dns-routing-deletion \
						delete-service-slave wait-for-service-slave-deletion \
						delete-service-master wait-for-service-master-deletion \
						delete-cluster wait-for-cluster-deletion

gerrit-publish:
	$(MAKE) -C ../gerrit gerrit-publish RECIPE=master-slave

git-daemon-publish:
	$(MAKE) -C git-daemon git-daemon-publish

git-ssh-publish:
	$(MAKE) -C git-ssh git-ssh-publish

prometheus-publish:
	$(MAKE) -C ../monitoring/prometheus prometheus-publish RECIPE=master-slave

grafana-publish:
	$(MAKE) -C ../monitoring/grafana grafana-publish RECIPE=master-slave

service-monitoring:
	$(MAKE) -C ../monitoring service-monitoring RECIPE=master-slave

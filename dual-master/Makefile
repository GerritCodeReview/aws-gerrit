include setup.env
include ../Makefile.common

CLUSTER_TEMPLATE:=cf-cluster.yml
SERVICE_MASTER_TEMPLATE:=cf-service-master.yml
DNS_ROUTING_TEMPLATE:=cf-dns-route.yml
LOAD_BALANCER_TEMPLATE:=cf-service-lb.yml
AWS_FC_COMMAND=export AWS_PAGER=;aws cloudformation

.PHONY: create-all delete-all \
				cluster cluster-keys service-master-1 dns-routing \
				wait-for-cluster-creation wait-for-service-master-1-creation wait-for-service-master-2-creation wait-for-dns-routing-creation \
				wait-for-cluster-deletion wait-for-service-master-1-deletion wait-for-service-master-2-deletion wait-for-dns-routing-deletion \
				gerrit-build gerrit-publish

create-all: cluster wait-for-cluster-creation \
						service-master-1 wait-for-service-master-1-creation \
						service-master-2 wait-for-service-master-2-creation \
						service-lb wait-for-service-lb-creation \
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

service-master-1:
	$(AWS_FC_COMMAND) create-stack \
		--stack-name $(SERVICE_MASTER1_STACK_NAME) \
		--capabilities CAPABILITY_IAM  \
		--template-body file://`pwd`/$(SERVICE_MASTER_TEMPLATE) \
		--region $(AWS_REGION) \
		--parameters \
		ParameterKey=ClusterStackName,ParameterValue=$(CLUSTER_STACK_NAME) \
		ParameterKey=HostedZoneName,ParameterValue=$(HOSTED_ZONE_NAME) \
		ParameterKey=Subdomain,ParameterValue=$(MASTER1_SUBDOMAIN) \
		ParameterKey=DockerRegistryUrl,ParameterValue=$(DOCKER_REGISTRY_URI) \
		ParameterKey=CertificateArn,ParameterValue=$(SSL_CERTIFICATE_ARN) \
		ParameterKey=GerritKeyPrefix,ParameterValue=$(GERRIT_KEY_PREFIX)\
		ParameterKey=PeerSubdomain,ParameterValue=$(MASTER2_SUBDOMAIN) \
		ParameterKey=DockerImage,ParameterValue=aws-gerrit/gerrit:$(IMAGE_TAG) \
		ParameterKey=LBSubdomain,ParameterValue=$(LB_SUBDOMAIN)

service-master-2:
	$(AWS_FC_COMMAND) create-stack \
		--stack-name $(SERVICE_MASTER2_STACK_NAME) \
		--capabilities CAPABILITY_IAM  \
		--template-body file://`pwd`/$(SERVICE_MASTER_TEMPLATE) \
		--region $(AWS_REGION) \
		--parameters \
		ParameterKey=ClusterStackName,ParameterValue=$(CLUSTER_STACK_NAME) \
		ParameterKey=HostedZoneName,ParameterValue=$(HOSTED_ZONE_NAME) \
		ParameterKey=Subdomain,ParameterValue=$(MASTER2_SUBDOMAIN) \
		ParameterKey=DockerRegistryUrl,ParameterValue=$(DOCKER_REGISTRY_URI) \
		ParameterKey=CertificateArn,ParameterValue=$(SSL_CERTIFICATE_ARN) \
		ParameterKey=HTTPHostPort,ParameterValue=$(HTTP_HOST_PORT_MASTER2) \
		ParameterKey=SSHHostPort,ParameterValue=$(SSH_HOST_PORT_MASTER2) \
		ParameterKey=GerritKeyPrefix,ParameterValue=$(GERRIT_KEY_PREFIX)\
		ParameterKey=DockerImage,ParameterValue=aws-gerrit/gerrit:$(IMAGE_TAG) \
		ParameterKey=GerritDataVolume,ParameterValue=gerrit-data-master-2 \
		ParameterKey=GerritIndexVolume,ParameterValue=gerrit-index-master-2 \
		ParameterKey=GerritCacheVolume,ParameterValue=gerrit-cache-master-2 \
		ParameterKey=GerritDbVolume,ParameterValue=gerrit-db-master-2 \
		ParameterKey=GerritLogsVolume,ParameterValue=gerrit-logs-master-2 \
		ParameterKey=PeerSubdomain,ParameterValue=$(MASTER1_SUBDOMAIN) \
		ParameterKey=LBSubdomain,ParameterValue=$(LB_SUBDOMAIN)

service-lb:
	$(AWS_FC_COMMAND) create-stack \
		--stack-name $(LOAD_BALANCER_STACK_NAME) \
		--capabilities CAPABILITY_IAM  \
		--template-body file://`pwd`/$(LOAD_BALANCER_TEMPLATE) \
		--region $(AWS_REGION) \
		--parameters \
		ParameterKey=ClusterStackName,ParameterValue=$(CLUSTER_STACK_NAME) \
		ParameterKey=Master1ServiceStackName,ParameterValue=$(SERVICE_MASTER1_STACK_NAME) \
		ParameterKey=Master2ServiceStackName,ParameterValue=$(SERVICE_MASTER2_STACK_NAME) \
		ParameterKey=HostedZoneName,ParameterValue=$(HOSTED_ZONE_NAME) \
		ParameterKey=DockerRegistryUrl,ParameterValue=$(DOCKER_REGISTRY_URI) \
		ParameterKey=GerritKeyPrefix,ParameterValue=$(GERRIT_KEY_PREFIX)\
		ParameterKey=CertificateArn,ParameterValue=$(SSL_CERTIFICATE_ARN) \
		ParameterKey=Subdomain,ParameterValue=$(LB_SUBDOMAIN) \
		ParameterKey=HTTPGerritMaster1Port,ParameterValue=$(HTTP_HOST_PORT_MASTER1) \
		ParameterKey=SSHGerritMaster1Port,ParameterValue=$(SSH_HOST_PORT_MASTER1) \
		ParameterKey=HTTPGerritMaster2Port,ParameterValue=$(HTTP_HOST_PORT_MASTER2) \
		ParameterKey=SSHGerritMaster2Port,ParameterValue=$(SSH_HOST_PORT_MASTER2) \
		ParameterKey=HAProxyDockerImage,ParameterValue=aws-gerrit/haproxy:$(IMAGE_TAG) \
		ParameterKey=SidecarDockerImage,ParameterValue=aws-gerrit/syslog-sidecar:$(IMAGE_TAG)


dns-routing:
	$(AWS_FC_COMMAND) create-stack \
		--stack-name $(DNS_ROUTING_STACK_NAME) \
		--capabilities CAPABILITY_IAM  \
		--template-body file://`pwd`/$(DNS_ROUTING_TEMPLATE) \
		--region $(AWS_REGION) \
		--parameters \
		ParameterKey=Master1ServiceStackName,ParameterValue=$(SERVICE_MASTER1_STACK_NAME) \
		ParameterKey=Master2ServiceStackName,ParameterValue=$(SERVICE_MASTER2_STACK_NAME) \
		ParameterKey=LBServiceStackName,ParameterValue=$(LOAD_BALANCER_STACK_NAME)


wait-for-cluster-creation:
	@echo "*** Wait for cluster stack '$(CLUSTER_STACK_NAME)' creation"
	$(AWS_FC_COMMAND) wait stack-create-complete \
	--stack-name $(CLUSTER_STACK_NAME) \
	--region $(AWS_REGION)
	@echo "*** Cluster stack '$(CLUSTER_STACK_NAME)' created"

wait-for-service-master-1-creation:
	@echo "*** Wait for service master stack '$(SERVICE_MASTER1_STACK_NAME)' creation"
	$(AWS_FC_COMMAND) wait stack-create-complete \
	--stack-name $(SERVICE_MASTER1_STACK_NAME) \
	--region $(AWS_REGION)
	@echo "*** Service stack '$(SERVICE_MASTER1_STACK_NAME)' created"

wait-for-service-master-2-creation:
	@echo "*** Wait for service master stack '$(SERVICE_MASTER2_STACK_NAME)' creation"
	$(AWS_FC_COMMAND) wait stack-create-complete \
	--stack-name $(SERVICE_MASTER2_STACK_NAME) \
	--region $(AWS_REGION)
	@echo "*** Service stack '$(SERVICE_MASTER2_STACK_NAME)' created"

wait-for-service-lb-creation:
	@echo "*** Wait for service lb stack '$(LOAD_BALANCER_STACK_NAME)' creation"
	$(AWS_FC_COMMAND) wait stack-create-complete \
	--stack-name $(LOAD_BALANCER_STACK_NAME) \
	--region $(AWS_REGION)
	@echo "*** Service stack '$(LOAD_BALANCER_STACK_NAME)' created"

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

wait-for-service-master-1-deletion:
	@echo "*** Wait for service master stack '$(SERVICE_MASTER1_STACK_NAME)' deletion"
	$(AWS_FC_COMMAND) wait stack-delete-complete \
	--stack-name $(SERVICE_MASTER1_STACK_NAME) \
	--region $(AWS_REGION)
	@echo "*** Service stack master '$(SERVICE_MASTER1_STACK_NAME)' deleted"

wait-for-service-master-2-deletion:
	@echo "*** Wait for service master stack '$(SERVICE_MASTER2_STACK_NAME)' deletion"
	$(AWS_FC_COMMAND) wait stack-delete-complete \
	--stack-name $(SERVICE_MASTER2_STACK_NAME) \
	--region $(AWS_REGION)
	@echo "*** Service stack master '$(SERVICE_MASTER2_STACK_NAME)' deleted"

wait-for-service-lb-deletion:
	@echo "*** Wait for service lb stack '$(LOAD_BALANCER_STACK_NAME)' deletion"
	$(AWS_FC_COMMAND) wait stack-delete-complete \
	--stack-name $(LOAD_BALANCER_STACK_NAME) \
	--region $(AWS_REGION)
	@echo "*** Service stack '$(LOAD_BALANCER_STACK_NAME)' deleted"

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

delete-service-master-1:
	$(AWS_FC_COMMAND) delete-stack \
	--stack-name $(SERVICE_MASTER1_STACK_NAME) \
	--region $(AWS_REGION)

delete-service-master-2:
	$(AWS_FC_COMMAND) delete-stack \
	--stack-name $(SERVICE_MASTER2_STACK_NAME) \
	--region $(AWS_REGION)

delete-service-lb:
	$(AWS_FC_COMMAND) delete-stack \
	--stack-name $(LOAD_BALANCER_STACK_NAME) \
	--region $(AWS_REGION)

delete-dns-routing:
	$(AWS_FC_COMMAND) delete-stack \
	--stack-name $(DNS_ROUTING_STACK_NAME) \
	--region $(AWS_REGION)

delete-all: delete-dns-routing wait-for-dns-routing-deletion \
						delete-service-lb wait-for-service-lb-deletion \
						delete-service-master-1 wait-for-service-master-1-deletion \
						delete-service-master-2 wait-for-service-master-2-deletion \
						delete-cluster wait-for-cluster-deletion

gerrit-publish:
	$(MAKE) -C ../gerrit gerrit-publish RECIPE=dual-master

haproxy-publish:
	$(MAKE) -C haproxy haproxy-publish

syslog-sidecar-publish:
	$(MAKE) -C syslog-sidecar syslog-sidecar-publish

include ../common.env # Must be included before setup.env because the latter depends on it
include setup.env
include ../Makefile.common

CLUSTER_TEMPLATE:=cf-cluster.yml
SERVICE_MASTER_TEMPLATE:=cf-service-master.yml
SERVICE_SLAVE_TEMPLATE:=cf-service-slave.yml
DNS_ROUTING_TEMPLATE:=cf-dns-route.yml
CLOUDWATCH_DASHBOARD_TEMPLATE:=cf-dashboard.yml
AWS_FC_COMMAND=export AWS_PAGER=;aws cloudformation

.PHONY: create-all delete-all \
				cluster cluster-keys service-master service-slave dns-routing dashboard \
				delete-cluster delete-service-master delete-service-slave delete-dns-routing delete-dashboard \
				wait-for-cluster-creation wait-for-service-master-creation wait-for-dns-routing-creation wait-for-dashboard \
				wait-for-cluster-deletion wait-for-service-master-deletion wait-for-dns-routing-deletion wait-for-dashboard-deletion \
				gerrit-build gerrit-publish

ifeq ($(METRICS_CLOUDWATCH_ENABLED),true)
optional_dashboard_targets=dashboard wait-for-dashboard-creation
endif

create-all: upload-common-templates \
						gerrit-publish git-daemon-publish git-ssh-publish \
						cluster wait-for-cluster-creation \
						service-slave service-master \
						wait-for-service-master-creation wait-for-service-slave-creation \
						$(optional_dashboard_targets) \
						dns-routing wait-for-dns-routing-creation

cluster: cluster-keys
ifdef CLUSTER_INSTANCE_TYPE
		$(eval CLUSTER_OPTIONAL_PARAMS := $(CLUSTER_OPTIONAL_PARAMS) ParameterKey=InstanceType,ParameterValue=$(CLUSTER_INSTANCE_TYPE))
endif

	$(AWS_FC_COMMAND) create-stack \
		--stack-name $(CLUSTER_STACK_NAME) \
		--capabilities CAPABILITY_IAM  \
		--template-body file://`pwd`/$(CLUSTER_TEMPLATE) \
		--region $(AWS_REGION) \
		--parameters \
		ParameterKey=DesiredCapacity,ParameterValue=$(CLUSTER_DESIRED_CAPACITY) \
		ParameterKey=ECSKeyName,ParameterValue=$(CLUSTER_KEYS) \
		ParameterKey=TemplateBucketName,ParameterValue=$(TEMPLATE_BUCKET_NAME) \
		ParameterKey=InternetGatewayIdProp,ParameterValue=$(INTERNET_GATEWAY_ID) \
		ParameterKey=VPCIdProp,ParameterValue=$(VPC_ID) \
		ParameterKey=SubnetIdProp,ParameterValue=$(SUBNET_ID) \
		$(CLUSTER_OPTIONAL_PARAMS)

service-master: set-optional-params-metrics-cloudwatch set-optional-params-smtp
ifdef LOAD_BALANCER_SCHEME
		$(eval MASTER_SERVICE_OPTIONAL_PARAMS := $(MASTER_SERVICE_OPTIONAL_PARAMS) ParameterKey=LoadBalancerScheme,ParameterValue=$(LOAD_BALANCER_SCHEME))
endif
ifdef GERRIT_MASTER_INSTANCE_ID
		$(eval MASTER_SERVICE_OPTIONAL_PARAMS := $(MASTER_SERVICE_OPTIONAL_PARAMS) ParameterKey=InstanceId,ParameterValue=$(GERRIT_MASTER_INSTANCE_ID))
endif
ifdef LDAP_ACCOUNT_PATTERN
		$(eval MASTER_SERVICE_OPTIONAL_PARAMS := $(MASTER_SERVICE_OPTIONAL_PARAMS) ParameterKey=LDAPAccountPattern,ParameterValue=\"$(LDAP_ACCOUNT_PATTERN)\")
endif

	$(AWS_FC_COMMAND) create-stack \
		--stack-name $(SERVICE_MASTER_STACK_NAME) \
		--capabilities CAPABILITY_IAM  \
		--template-body file://`pwd`/$(SERVICE_MASTER_TEMPLATE) \
		--region $(AWS_REGION) \
		--parameters \
		ParameterKey=LDAPServer,ParameterValue=$(LDAP_SERVER) \
		ParameterKey=LDAPUsername,ParameterValue=\"$(LDAP_USERNAME)\" \
		ParameterKey=LDAPAccountBase,ParameterValue=\"$(LDAP_ACCOUNT_BASE)\" \
		ParameterKey=LDAPGroupBase,ParameterValue=\"$(LDAP_GROUP_BASE)\" \
		ParameterKey=SMTPServer,ParameterValue=$(SMTP_SERVER) \
		ParameterKey=SMTPUser,ParameterValue=$(SMTP_USER) \
		ParameterKey=SMTPDomain,ParameterValue=$(SMTP_DOMAIN) \
		ParameterKey=ClusterStackName,ParameterValue=$(CLUSTER_STACK_NAME) \
		ParameterKey=TemplateBucketName,ParameterValue=$(TEMPLATE_BUCKET_NAME) \
		ParameterKey=HostedZoneName,ParameterValue=$(HOSTED_ZONE_NAME) \
		ParameterKey=Subdomain,ParameterValue=$(MASTER_SUBDOMAIN) \
		ParameterKey=SlaveSubdomain,ParameterValue=$(SLAVE_SUBDOMAIN) \
		ParameterKey=DockerRegistryUrl,ParameterValue=$(DOCKER_REGISTRY_URI) \
		ParameterKey=CertificateArn,ParameterValue=$(SSL_CERTIFICATE_ARN) \
		ParameterKey=SlaveServiceStackName,ParameterValue=$(SERVICE_SLAVE_STACK_NAME) \
		ParameterKey=GerritKeyPrefix,ParameterValue=$(GERRIT_KEY_PREFIX)\
		ParameterKey=DockerImage,ParameterValue=aws-gerrit/gerrit:$(IMAGE_TAG) \
		ParameterKey=GerritRAM,ParameterValue=$(GERRIT_RAM) \
		ParameterKey=GerritCPU,ParameterValue=$(GERRIT_CPU) \
		ParameterKey=GerritHeapLimit,ParameterValue=$(GERRIT_HEAP_LIMIT) \
		ParameterKey=JgitCacheSize,ParameterValue=$(JGIT_CACHE_SIZE) \
		$(MASTER_SERVICE_OPTIONAL_PARAMS) \
		$(METRICS_CW_OPTIONAL_PARAMS) \
		$(SMTP_OPTIONAL_PARAMS)

service-slave: set-optional-params-metrics-cloudwatch
ifdef LOAD_BALANCER_SCHEME
		$(eval SLAVE_SERVICE_OPTIONAL_PARAMS := $(SLAVE_SERVICE_OPTIONAL_PARAMS) ParameterKey=LoadBalancerScheme,ParameterValue=$(LOAD_BALANCER_SCHEME))
endif
ifdef GERRIT_SLAVE_INSTANCE_ID
		$(eval SLAVE_SERVICE_OPTIONAL_PARAMS := $(SLAVE_SERVICE_OPTIONAL_PARAMS) ParameterKey=InstanceId,ParameterValue=$(GERRIT_SLAVE_INSTANCE_ID))
endif
ifdef LDAP_ACCOUNT_PATTERN
		$(eval SLAVE_SERVICE_OPTIONAL_PARAMS := $(SLAVE_SERVICE_OPTIONAL_PARAMS) ParameterKey=LDAPAccountPattern,ParameterValue=\"$(LDAP_ACCOUNT_PATTERN)\")
endif

	$(AWS_FC_COMMAND) create-stack \
		--stack-name $(SERVICE_SLAVE_STACK_NAME) \
		--capabilities CAPABILITY_IAM  \
		--template-body file://`pwd`/$(SERVICE_SLAVE_TEMPLATE) \
		--region $(AWS_REGION) \
		--parameters \
		ParameterKey=LDAPServer,ParameterValue=$(LDAP_SERVER) \
		ParameterKey=LDAPUsername,ParameterValue=\"$(LDAP_USERNAME)\" \
		ParameterKey=LDAPAccountBase,ParameterValue=\"$(LDAP_ACCOUNT_BASE)\" \
		ParameterKey=LDAPGroupBase,ParameterValue=\"$(LDAP_GROUP_BASE)\" \
		ParameterKey=ClusterStackName,ParameterValue=$(CLUSTER_STACK_NAME) \
		ParameterKey=TemplateBucketName,ParameterValue=$(TEMPLATE_BUCKET_NAME) \
		ParameterKey=HostedZoneName,ParameterValue=$(HOSTED_ZONE_NAME) \
		ParameterKey=Subdomain,ParameterValue=$(SLAVE_SUBDOMAIN) \
		ParameterKey=DockerRegistryUrl,ParameterValue=$(DOCKER_REGISTRY_URI) \
		ParameterKey=CertificateArn,ParameterValue=$(SSL_CERTIFICATE_ARN) \
		ParameterKey=GerritKeyPrefix,ParameterValue=$(GERRIT_KEY_PREFIX)\
		ParameterKey=GerritDockerImage,ParameterValue=aws-gerrit/gerrit:$(IMAGE_TAG) \
		ParameterKey=GerritRAM,ParameterValue=$(GERRIT_RAM) \
		ParameterKey=GerritCPU,ParameterValue=$(GERRIT_CPU) \
		ParameterKey=GerritHeapLimit,ParameterValue=$(GERRIT_HEAP_LIMIT) \
		ParameterKey=JgitCacheSize,ParameterValue=$(JGIT_CACHE_SIZE) \
		$(SLAVE_SERVICE_OPTIONAL_PARAMS) \
		$(METRICS_CW_OPTIONAL_PARAMS)

dns-routing:
	$(AWS_FC_COMMAND) create-stack \
		--stack-name $(DNS_ROUTING_STACK_NAME) \
		--capabilities CAPABILITY_IAM  \
		--template-body file://`pwd`/$(DNS_ROUTING_TEMPLATE) \
		--region $(AWS_REGION) \
		--parameters \
		ParameterKey=MasterServiceStackName,ParameterValue=$(SERVICE_MASTER_STACK_NAME) \
		ParameterKey=SlaveServiceStackName,ParameterValue=$(SERVICE_SLAVE_STACK_NAME)

dashboard:
ifeq ($(METRICS_CLOUDWATCH_ENABLED),true)
ifdef GERRIT_MASTER_INSTANCE_ID
	$(eval DASHBOARD_OPTIONAL_PARAMS := $(DASHBOARD_OPTIONAL_PARAMS) ParameterKey=MasterInstanceId,ParameterValue=$(GERRIT_MASTER_INSTANCE_ID))
endif
ifdef GERRIT_SLAVE_INSTANCE_ID
	$(eval DASHBOARD_OPTIONAL_PARAMS := $(DASHBOARD_OPTIONAL_PARAMS) ParameterKey=SlaveInstanceId,ParameterValue=$(GERRIT_SLAVE_INSTANCE_ID))
endif
ifdef METRICS_CLOUDWATCH_NAMESPACE
	$(eval DASHBOARD_OPTIONAL_PARAMS := $(DASHBOARD_OPTIONAL_PARAMS) ParameterKey=MetricsCloudwatchNamespace,ParameterValue=$(METRICS_CLOUDWATCH_NAMESPACE))
endif

	$(AWS_FC_COMMAND) create-stack \
		--stack-name $(DASHBOARD_STACK_NAME) \
		--capabilities CAPABILITY_IAM  \
		--template-body file://`pwd`/$(CLOUDWATCH_DASHBOARD_TEMPLATE) \
		--region $(AWS_REGION) \
		--parameters \
		$(DASHBOARD_OPTIONAL_PARAMS)

else
		@echo "METRICS_CLOUDWATCH_ENABLED is set to false. Dashboard creation skipped".
endif


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

wait-for-dashboard-creation:
	@echo "*** Wait for dashboard stack '$(DASHBOARD_STACK_NAME)' creation"
	$(AWS_FC_COMMAND) wait stack-create-complete \
	--stack-name $(DASHBOARD_STACK_NAME) \
	--region $(AWS_REGION)
	@echo "*** Dashboard stack '$(DASHBOARD_STACK_NAME)' created"

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

wait-for-dashboard-deletion:
	@echo "*** Wait for dashboard stack '$(DASHBOARD_STACK_NAME)' deletion"
	$(AWS_FC_COMMAND) wait stack-delete-complete \
	--stack-name $(DASHBOARD_STACK_NAME) \
	--region $(AWS_REGION)
	@echo "*** Dashboard stack '$(DASHBOARD_STACK_NAME)' deleted"

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

delete-dashboard:
	$(AWS_FC_COMMAND) delete-stack \
	--stack-name $(DASHBOARD_STACK_NAME) \
	--region $(AWS_REGION)

delete-all: delete-dns-routing wait-for-dns-routing-deletion \
						delete-service-slave wait-for-service-slave-deletion \
						delete-service-master wait-for-service-master-deletion \
						delete-cluster wait-for-cluster-deletion \
						delete-dashboard wait-for-dashboard-deletion

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

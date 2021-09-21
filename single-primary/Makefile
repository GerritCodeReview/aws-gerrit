include ../common.env # Must be included before setup.env because the latter depends on it
include setup.env
include ../Makefile.common
include ../maintenance/git-gc/Makefile

CLUSTER_TEMPLATE:=cf-cluster.yml
SERVICE_TEMPLATE:=cf-service.yml
DNS_ROUTING_TEMPLATE:=cf-dns-route.yml
AWS_FC_COMMAND=export AWS_PAGER=;aws cloudformation
GIT_GC_SOURCE_PATH=/gerrit-mount-point/gerrit-git

.PHONY: create-all delete-all \
				cluster cluster-keys service dns-routing \
				wait-for-cluster-creation wait-for-service-creation wait-for-dns-routing-creation \
				wait-for-cluster-deletion wait-for-service-deletion wait-for-dns-routing-deletion \
				gerrit-build gerrit-publish

create-all: upload-common-templates \
						gerrit-publish \
						cluster wait-for-cluster-creation \
						service wait-for-service-creation \
						$(optional_git_gc_targets_creation) \
						dns-routing wait-for-dns-routing-creation

cluster: cluster-keys set-optional-gerrit-primary-volume set-optional-network-params
ifdef CLUSTER_INSTANCE_TYPE
		$(eval CLUSTER_OPTIONAL_PARAMS := $(CLUSTER_OPTIONAL_PARAMS) ParameterKey=InstanceType,ParameterValue=$(CLUSTER_INSTANCE_TYPE))
endif

	$(AWS_FC_COMMAND) create-stack \
		--stack-name $(CLUSTER_STACK_NAME) \
		--capabilities CAPABILITY_IAM  \
		--template-body file://`pwd`/$(CLUSTER_TEMPLATE) \
		--region $(AWS_REGION) \
		--parameters \
		ParameterKey=ECSKeyName,ParameterValue=$(CLUSTER_KEYS) \
		ParameterKey=TemplateBucketName,ParameterValue=$(TEMPLATE_BUCKET_NAME) \
		$(GERRIT_OPTIONAL_PARAMS_NETWORK) \
		$(CLUSTER_OPTIONAL_PARAMS) \
		$(GERRIT_OPTIONAL_PRIMARY_VOLUME)

service: set-optional-params-metrics-cloudwatch \
			set-optional-params-smtp \
			set-ldap-account-pattern \
			set-optional-gerrit-ulimits \
			set-optional-jgit-conf \
			set-optional-x-ray
ifdef LOAD_BALANCER_SCHEME
		$(eval SERVICE_OPTIONAL_PARAMS := $(SERVICE_OPTIONAL_PARAMS) ParameterKey=LoadBalancerScheme,ParameterValue=$(LOAD_BALANCER_SCHEME))
endif
ifdef GERRIT_INSTANCE_ID
		$(eval SERVICE_OPTIONAL_PARAMS := $(SERVICE_OPTIONAL_PARAMS) ParameterKey=InstanceId,ParameterValue=$(GERRIT_INSTANCE_ID))
endif

	$(AWS_FC_COMMAND) create-stack \
		--stack-name $(SERVICE_STACK_NAME) \
		--capabilities CAPABILITY_IAM  \
		--template-body file://`pwd`/$(SERVICE_TEMPLATE) \
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
		ParameterKey=Subdomain,ParameterValue=$(SUBDOMAIN) \
		ParameterKey=DockerRegistryUrl,ParameterValue=$(DOCKER_REGISTRY_URI) \
		ParameterKey=CertificateArn,ParameterValue=$(SSL_CERTIFICATE_ARN) \
		ParameterKey=GerritKeyPrefix,ParameterValue=$(GERRIT_KEY_PREFIX) \
		ParameterKey=DockerImage,ParameterValue=aws-gerrit/gerrit:$(IMAGE_TAG)\
		ParameterKey=GerritRAM,ParameterValue=$(GERRIT_RAM) \
		ParameterKey=GerritCPU,ParameterValue=$(GERRIT_CPU) \
		ParameterKey=GerritHeapLimit,ParameterValue=$(GERRIT_HEAP_LIMIT) \
		ParameterKey=JgitCacheSize,ParameterValue=$(JGIT_CACHE_SIZE) \
		$(JGIT_OPTIONAL_PARAMS) \
		$(LDAP_ACCOUNT_PATTERN_PARAM) \
		$(SERVICE_OPTIONAL_PARAMS) \
		$(METRICS_CW_OPTIONAL_PARAMS) \
		$(SMTP_OPTIONAL_PARAMS) \
		$(GERRIT_ULIMITS) \
		$(XRAY_OPTIONAL_PARAMS)

dns-routing:
	$(AWS_FC_COMMAND) create-stack \
		--stack-name $(DNS_ROUTING_STACK_NAME) \
		--capabilities CAPABILITY_IAM  \
		--template-body file://`pwd`/$(DNS_ROUTING_TEMPLATE) \
		--region $(AWS_REGION) \
		--parameters \
		ParameterKey=ServiceStackName,ParameterValue=$(SERVICE_STACK_NAME)

wait-for-cluster-creation:
	@echo "*** Wait for cluster stack '$(CLUSTER_STACK_NAME)' creation"
	$(AWS_FC_COMMAND) wait stack-create-complete \
	--stack-name $(CLUSTER_STACK_NAME) \
	--region $(AWS_REGION)
	@echo "*** Cluster stack '$(CLUSTER_STACK_NAME)' created"

wait-for-service-creation:
	@echo "*** Wait for service stack '$(SERVICE_STACK_NAME)' creation"
	$(AWS_FC_COMMAND) wait stack-create-complete \
	--stack-name $(SERVICE_STACK_NAME) \
	--region $(AWS_REGION)
	@echo "*** Service stack '$(SERVICE_STACK_NAME)' created"

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

wait-for-service-deletion:
	@echo "*** Wait for service stack '$(SERVICE_STACK_NAME)' deletion"
	$(AWS_FC_COMMAND) wait stack-delete-complete \
	--stack-name $(SERVICE_STACK_NAME) \
	--region $(AWS_REGION)
	@echo "*** Service stack '$(SERVICE_STACK_NAME)' deleted"

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

delete-service:
	$(AWS_FC_COMMAND) delete-stack \
	--stack-name $(SERVICE_STACK_NAME) \
	--region $(AWS_REGION)

delete-dns-routing:
	$(AWS_FC_COMMAND) delete-stack \
	--stack-name $(DNS_ROUTING_STACK_NAME) \
	--region $(AWS_REGION)

delete-all: delete-dns-routing wait-for-dns-routing-deletion \
						delete-service wait-for-service-deletion \
						$(optional_git_gc_targets_deletion) \
						delete-cluster wait-for-cluster-deletion

gerrit-publish:
	$(MAKE) -C ../gerrit gerrit-publish RECIPE=single-primary

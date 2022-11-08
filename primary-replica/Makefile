include ../common.env # Must be included before setup.env because the latter depends on it
include setup.env
include ../Makefile.common
include ../maintenance/git-gc/Makefile

CLUSTER_TEMPLATE:=cf-cluster.yml
SERVICE_PRIMARY_TEMPLATE:=cf-service-primary.yml
SERVICE_REPLICA_TEMPLATE:=cf-service-replica.yml
DNS_ROUTING_TEMPLATE:=cf-dns-route.yml
CLOUDWATCH_DASHBOARD_TEMPLATE:=cf-dashboard.yml
AWS_FC_COMMAND=export AWS_PAGER=;aws cloudformation
GIT_GC_SOURCE_PATH=/gerrit-mount-point/gerrit-git
PLUGINS=javamelody healthcheck metrics-reporter-cloudwatch pull-replication
PLUGINS_LIBS_LINKS=pull-replication

.PHONY: create-all delete-all \
				cluster cluster-keys service-primary service-replica dns-routing dashboard \
				delete-cluster delete-service-primary delete-service-replica delete-dns-routing delete-dashboard \
				wait-for-cluster-creation wait-for-service-primary-creation wait-for-dns-routing-creation wait-for-dashboard \
				wait-for-cluster-deletion wait-for-service-primary-deletion wait-for-dns-routing-deletion wait-for-dashboard-deletion \
				gerrit-build gerrit-publish

ifeq ($(METRICS_CLOUDWATCH_ENABLED),true)
optional_dashboard_targets=dashboard wait-for-dashboard-creation
endif

create-all: upload-common-templates \
						gerrit-publish git-daemon-publish git-ssh-publish \
						cluster wait-for-cluster-creation \
						service-replica service-primary \
						wait-for-service-primary-creation wait-for-service-replica-creation \
						$(optional_dashboard_targets) \
						$(optional_git_gc_targets_creation) \
						dns-routing wait-for-dns-routing-creation

cluster: cluster-keys set-optional-gerrit-primary-volume \
			set-optional-params-for-replica-filesystem \
			set-optional-params-for-replica-auto-scaling-capacity \
			set-optional-params-for-replica-capacity-provider \
			set-optional-network-params
ifdef CLUSTER_INSTANCE_TYPE
		$(eval CLUSTER_OPTIONAL_PARAMS := $(CLUSTER_OPTIONAL_PARAMS) ParameterKey=InstanceType,ParameterValue=$(CLUSTER_INSTANCE_TYPE))
endif
ifdef PRIMARY_MAX_COUNT
		$(eval CLUSTER_OPTIONAL_PARAMS := $(CLUSTER_OPTIONAL_PARAMS) ParameterKey=PrimaryMaxCount,ParameterValue=$(PRIMARY_MAX_COUNT))
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
		$(GERRIT_OPTIONAL_PRIMARY_VOLUME) \
		$(GERRIT_OPTIONAL_PARAMS_REPLICA_FILESYSTEM) \
		$(GERRIT_OPTIONAL_PARAMS_REPLICA_AUTO_SCALING_CAPACITY) \
		$(GERRIT_OPTIONAL_PARAMS_REPLICA_CAPACITY_PROVIDER)

service-primary: set-optional-params-metrics-cloudwatch set-optional-params-smtp set-ldap-account-pattern set-optional-gerrit-ulimits set-optional-jgit-conf \
					set-optional-x-ray
ifdef LOAD_BALANCER_SCHEME
		$(eval PRIMARY_SERVICE_OPTIONAL_PARAMS := $(PRIMARY_SERVICE_OPTIONAL_PARAMS) ParameterKey=LoadBalancerScheme,ParameterValue=$(LOAD_BALANCER_SCHEME))
endif
ifdef GERRIT_PRIMARY_INSTANCE_ID
		$(eval PRIMARY_SERVICE_OPTIONAL_PARAMS := $(PRIMARY_SERVICE_OPTIONAL_PARAMS) ParameterKey=InstanceId,ParameterValue=$(GERRIT_PRIMARY_INSTANCE_ID))
endif

	$(AWS_FC_COMMAND) create-stack \
		--stack-name $(SERVICE_PRIMARY_STACK_NAME) \
		--capabilities CAPABILITY_IAM  \
		--template-body file://`pwd`/$(SERVICE_PRIMARY_TEMPLATE) \
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
		ParameterKey=HttpSubdomain,ParameterValue=$(HTTP_PRIMARY_SUBDOMAIN) \
		ParameterKey=SshSubdomain,ParameterValue=$(SSH_PRIMARY_SUBDOMAIN) \
		ParameterKey=SshReplicaSubdomain,ParameterValue=$(SSH_REPLICA_SUBDOMAIN) \
		ParameterKey=DockerRegistryUrl,ParameterValue=$(DOCKER_REGISTRY_URI) \
		ParameterKey=CertificateArn,ParameterValue=$(SSL_CERTIFICATE_ARN) \
		ParameterKey=ReplicaServiceStackName,ParameterValue=$(SERVICE_REPLICA_STACK_NAME) \
		ParameterKey=GerritKeyPrefix,ParameterValue=$(GERRIT_KEY_PREFIX)\
		ParameterKey=DockerImage,ParameterValue=aws-gerrit/gerrit:$(IMAGE_TAG) \
		ParameterKey=GerritRAM,ParameterValue=$(GERRIT_RAM) \
		ParameterKey=GerritCPU,ParameterValue=$(GERRIT_CPU) \
		ParameterKey=GerritHeapLimit,ParameterValue=$(GERRIT_HEAP_LIMIT) \
		ParameterKey=JgitCacheSize,ParameterValue=$(JGIT_CACHE_SIZE) \
		ParameterKey=HttpReplicaSubdomain,ParameterValue=$(HTTP_REPLICA_SUBDOMAIN) \
		$(JGIT_OPTIONAL_PARAMS) \
		$(LDAP_ACCOUNT_PATTERN_PARAM) \
		$(PRIMARY_SERVICE_OPTIONAL_PARAMS) \
		$(METRICS_CW_OPTIONAL_PARAMS) \
		$(SMTP_OPTIONAL_PARAMS) \
		$(GERRIT_ULIMITS) \
		$(XRAY_OPTIONAL_PARAMS)


service-replica: set-optional-params-metrics-cloudwatch \
					set-ldap-account-pattern \
					set-optional-gerrit-ulimits set-optional-jgit-conf \
					set-optional-params-for-replica-auto-scaling-capacity \
					set-optional-params-for-replica-auto-scaling-policy \
					set-optional-x-ray

ifdef LOAD_BALANCER_SCHEME
		$(eval REPLICA_SERVICE_OPTIONAL_PARAMS := $(REPLICA_SERVICE_OPTIONAL_PARAMS) ParameterKey=LoadBalancerScheme,ParameterValue=$(LOAD_BALANCER_SCHEME))
endif

ifdef GERRIT_REPLICA_INSTANCE_ID
		$(eval REPLICA_SERVICE_OPTIONAL_PARAMS := $(REPLICA_SERVICE_OPTIONAL_PARAMS) ParameterKey=InstanceId,ParameterValue=$(GERRIT_REPLICA_INSTANCE_ID))
endif

	$(AWS_FC_COMMAND) create-stack \
		--stack-name $(SERVICE_REPLICA_STACK_NAME) \
		--capabilities CAPABILITY_IAM  \
		--template-body file://`pwd`/$(SERVICE_REPLICA_TEMPLATE) \
		--region $(AWS_REGION) \
		--parameters \
		ParameterKey=LDAPServer,ParameterValue=$(LDAP_SERVER) \
		ParameterKey=LDAPUsername,ParameterValue=\"$(LDAP_USERNAME)\" \
		ParameterKey=LDAPAccountBase,ParameterValue=\"$(LDAP_ACCOUNT_BASE)\" \
		ParameterKey=LDAPGroupBase,ParameterValue=\"$(LDAP_GROUP_BASE)\" \
		ParameterKey=ClusterStackName,ParameterValue=$(CLUSTER_STACK_NAME) \
		ParameterKey=TemplateBucketName,ParameterValue=$(TEMPLATE_BUCKET_NAME) \
		ParameterKey=HostedZoneName,ParameterValue=$(HOSTED_ZONE_NAME) \
		ParameterKey=HttpSubdomain,ParameterValue=$(HTTP_REPLICA_SUBDOMAIN) \
		ParameterKey=SshSubdomain,ParameterValue=$(SSH_REPLICA_SUBDOMAIN) \
		ParameterKey=DockerRegistryUrl,ParameterValue=$(DOCKER_REGISTRY_URI) \
		ParameterKey=CertificateArn,ParameterValue=$(SSL_CERTIFICATE_ARN) \
		ParameterKey=GerritKeyPrefix,ParameterValue=$(GERRIT_KEY_PREFIX)\
		ParameterKey=GerritDockerImage,ParameterValue=aws-gerrit/gerrit:$(IMAGE_TAG) \
		ParameterKey=GerritRAM,ParameterValue=$(GERRIT_RAM) \
		ParameterKey=GerritCPU,ParameterValue=$(GERRIT_CPU) \
		ParameterKey=GerritHeapLimit,ParameterValue=$(GERRIT_HEAP_LIMIT) \
		ParameterKey=JgitCacheSize,ParameterValue=$(JGIT_CACHE_SIZE) \
		ParameterKey=HttpPrimaryGerritSubdomain,ParameterValue=$(HTTP_PRIMARY_SUBDOMAIN) \
		ParameterKey=GerritPrimary1nstanceId,ParameterValue=$(GERRIT_PRIMARY_INSTANCE_ID) \
		ParameterKey=GerritPrimary2nstanceId,ParameterValue=$(GERRIT_PRIMARY_INSTANCE_ID) \
		$(JGIT_OPTIONAL_PARAMS) \
		$(LDAP_ACCOUNT_PATTERN_PARAM) \
		$(REPLICA_SERVICE_OPTIONAL_PARAMS) \
		$(METRICS_CW_OPTIONAL_PARAMS) \
		$(GERRIT_ULIMITS) \
		$(GERRIT_OPTIONAL_PARAMS_REPLICA_AUTO_SCALING_CAPACITY) \
		$(GERRIT_OPTIONAL_PARAMS_REPLICA_AUTO_SCALING_POLICY) \
		$(XRAY_OPTIONAL_PARAMS)

dns-routing:
	$(AWS_FC_COMMAND) create-stack \
		--stack-name $(DNS_ROUTING_STACK_NAME) \
		--capabilities CAPABILITY_IAM  \
		--template-body file://`pwd`/$(DNS_ROUTING_TEMPLATE) \
		--region $(AWS_REGION) \
		--parameters \
		ParameterKey=PrimaryServiceStackName,ParameterValue=$(SERVICE_PRIMARY_STACK_NAME)

dashboard:
ifeq ($(METRICS_CLOUDWATCH_ENABLED),true)
ifdef GERRIT_PRIMARY_INSTANCE_ID
	$(eval DASHBOARD_OPTIONAL_PARAMS := $(DASHBOARD_OPTIONAL_PARAMS) ParameterKey=PrimaryInstanceId,ParameterValue=$(GERRIT_PRIMARY_INSTANCE_ID))
endif
ifdef GERRIT_REPLICA_INSTANCE_ID
	$(eval DASHBOARD_OPTIONAL_PARAMS := $(DASHBOARD_OPTIONAL_PARAMS) ParameterKey=ReplicaInstanceId,ParameterValue=$(GERRIT_REPLICA_INSTANCE_ID))
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

delete-all-including-retained-stack: confirm-persistent-stack-deletion delete-all delete-git-replica-persistent-stack delete-network-persistent-stack

wait-for-cluster-creation:
	@echo "*** Wait for cluster stack '$(CLUSTER_STACK_NAME)' creation"
	$(AWS_FC_COMMAND) wait stack-create-complete \
	--stack-name $(CLUSTER_STACK_NAME) \
	--region $(AWS_REGION)
	@echo "*** Cluster stack '$(CLUSTER_STACK_NAME)' created"

wait-for-service-primary-creation:
	@echo "*** Wait for service primary stack '$(SERVICE_PRIMARY_STACK_NAME)' creation"
	$(AWS_FC_COMMAND) wait stack-create-complete \
	--stack-name $(SERVICE_PRIMARY_STACK_NAME) \
	--region $(AWS_REGION)
	@echo "*** Service stack '$(SERVICE_PRIMARY_STACK_NAME)' created"

wait-for-service-replica-creation:
	@echo "*** Wait for service replica stack '$(SERVICE_REPLICA_STACK_NAME)' creation"
	$(AWS_FC_COMMAND) wait stack-create-complete \
	--stack-name $(SERVICE_REPLICA_STACK_NAME) \
	--region $(AWS_REGION)
	@echo "*** Service stack '$(SERVICE_REPLICA_STACK_NAME)' created"

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

wait-for-service-primary-deletion:
	@echo "*** Wait for service primary stack '$(SERVICE_PRIMARY_STACK_NAME)' deletion"
	$(AWS_FC_COMMAND) wait stack-delete-complete \
	--stack-name $(SERVICE_PRIMARY_STACK_NAME) \
	--region $(AWS_REGION)
	@echo "*** Service stack primary '$(SERVICE_PRIMARY_STACK_NAME)' deleted"

wait-for-service-replica-deletion:
	@echo "*** Wait for service primary stack '$(SERVICE_REPLICA_STACK_NAME)' deletion"
	$(AWS_FC_COMMAND) wait stack-delete-complete \
	--stack-name $(SERVICE_REPLICA_STACK_NAME) \
	--region $(AWS_REGION)
	@echo "*** Service stack primary '$(SERVICE_REPLICA_STACK_NAME)' deleted"

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

delete-service-primary:
	$(AWS_FC_COMMAND) delete-stack \
	--stack-name $(SERVICE_PRIMARY_STACK_NAME) \
	--region $(AWS_REGION)

delete-service-replica:
	$(AWS_FC_COMMAND) delete-stack \
	--stack-name $(SERVICE_REPLICA_STACK_NAME) \
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
						delete-service-replica wait-for-service-replica-deletion \
						delete-service-primary wait-for-service-primary-deletion \
						delete-asg wait_for_asg_deletion \
						delete-cluster wait-for-cluster-deletion \
						$(optional_git_gc_targets_deletion) \
						delete-dashboard wait-for-dashboard-deletion

gerrit-publish:
	$(MAKE) -C ../gerrit gerrit-publish RECIPE=primary-replica PLUGINS="$(PLUGINS)" PLUGINS_LIBS_LINKS="$(PLUGINS_LIBS_LINKS)"

git-daemon-publish:
	$(MAKE) -C git-daemon git-daemon-publish

git-ssh-publish:
	$(MAKE) -C git-ssh git-ssh-publish

prometheus-publish:
	$(MAKE) -C ../monitoring/prometheus prometheus-publish RECIPE=primary-replica

grafana-publish:
	$(MAKE) -C ../monitoring/grafana grafana-publish RECIPE=primary-replica

service-monitoring:
	$(MAKE) -C ../monitoring service-monitoring RECIPE=primary-replica

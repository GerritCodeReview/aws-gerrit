include ../common.env # Must be included before setup.env because the latter depends on it
include setup.env
include ../Makefile.common
include ../maintenance/git-gc/Makefile

CLUSTER_TEMPLATE:=cf-cluster.yml
SERVICE_PRIMARY_TEMPLATE:=cf-service-primary.yml
SERVICE_REPLICA_TEMPLATE:=cf-service-replica.yml
DNS_ROUTING_TEMPLATE:=cf-dns-route.yml
CLOUDWATCH_DASHBOARD_TEMPLATE:=cf-dashboard.yml
LOAD_BALANCER_TEMPLATE:=cf-service-lb.yml
SERVICE_REPLICATION_TEMPLATE:=cf-service-replication.yml
AWS_FC_COMMAND=export AWS_PAGER=;aws cloudformation
GIT_GC_SOURCE_PATH=/mnt/efs/gerrit-shared/git

SINGLE_SITE_PLUGINS=javamelody high-availability healthcheck metrics-reporter-cloudwatch

MULTI_SITE_PLUGINS=$(SINGLE_SITE_PLUGINS) multi-site kafka-events websession-broker zookeeper-refdb~zk-3.5
MULTI_SITE_PLUGINS_LIBS_LINKS=multi-site replication
MULTI_SITE_MAVEN_LIBS=events-broker~$(EVENTSBROKER_LIB_VER)

.PHONY: create-all delete-all \
				wait-for-replication-creation wait-for-service-replication-deletion service-replication delete-service-replication \
				cluster cluster-keys service-primary-1 service-primary-2 service-replica dns-routing dashboard delete-dashboard\
				wait-for-cluster-creation wait-for-service-primary-1-creation wait-for-service-primary-2-creation wait-for-service-replica-creation wait-for-dns-routing-creation wait-for-dashboard-creation \
				wait-for-cluster-deletion wait-for-service-primary-1-deletion wait-for-service-primary-2-deletion wait-for-service-replica-deletion wait-for-dns-routing-deletion wait-for-dashboard-deletion \
				service-lb wait-for-service-lb-deletion wait-for-service-lb-creation \
				gerrit-build gerrit-publish haproxy-publish syslog-sidecar-publish

ifeq ($(REPLICATION_SERVICE_ENABLED),true)
optional_replication_targets_creation=service-replication wait-for-service-replication-creation
optional_replication_targets_deletion=delete-service-replication wait-for-service-replication-deletion
endif

ifeq ($(METRICS_CLOUDWATCH_ENABLED),true)
optional_dashboard_targets_creation=dashboard wait-for-dashboard-creation
optional_dashboard_targets_deletion=delete-dashboard wait-for-dashboard-deletion
endif

create-all: upload-common-templates \
						git-daemon-publish git-ssh-publish \
						gerrit-publish haproxy-publish syslog-sidecar-publish \
						cluster wait-for-cluster-creation \
						$(optional_replication_targets_creation) \
						service-replica service-primary-1 \
						wait-for-service-primary-1-creation wait-for-service-replica-creation \
						service-primary-2 wait-for-service-primary-2-creation \
						$(optional_dashboard_targets_creation) \
						service-lb wait-for-service-lb-creation \
						$(optional_git_gc_targets_creation) \
						dns-routing wait-for-dns-routing-creation

cluster: cluster-keys set-optional-gerrit-primary-volume \
			set-optional-params-for-replica-filesystem \
			set-optional-params-for-replica-auto-scaling-capacity \
			set-optional-params-for-replica-capacity-provider
ifdef CLUSTER_INSTANCE_TYPE
		$(eval CLUSTER_OPTIONAL_PARAMS := $(CLUSTER_OPTIONAL_PARAMS) ParameterKey=InstanceType,ParameterValue=$(CLUSTER_INSTANCE_TYPE))
endif
ifdef PRIMARY_FILESYSTEM_THROUGHPUT_MODE
		$(eval CLUSTER_OPTIONAL_PARAMS := $(CLUSTER_OPTIONAL_PARAMS) ParameterKey=PrimaryFileSystemThroughputMode,ParameterValue=$(PRIMARY_FILESYSTEM_THROUGHPUT_MODE))
endif
ifdef PRIMARY_FILESYSTEM_PROVISIONED_THROUGHPUT_IN_MIBPS
		$(eval CLUSTER_OPTIONAL_PARAMS := $(CLUSTER_OPTIONAL_PARAMS) ParameterKey=PrimaryProvisionedThroughputInMibps,ParameterValue=$(PRIMARY_FILESYSTEM_PROVISIONED_THROUGHPUT_IN_MIBPS))
endif
ifdef PRIMARY_FILESYSTEM_ID
		$(eval CLUSTER_OPTIONAL_PARAMS := $(CLUSTER_OPTIONAL_PARAMS) ParameterKey=PrimaryFileSystemID,ParameterValue=$(PRIMARY_FILESYSTEM_ID))
endif
ifdef SUBNET_CIDR
		$(eval CLUSTER_OPTIONAL_PARAMS := $(CLUSTER_OPTIONAL_PARAMS) ParameterKey=SubnetCIDR,ParameterValue=$(SUBNET_CIDR))
endif
ifdef VPC_CIDR
		$(eval CLUSTER_OPTIONAL_PARAMS := $(CLUSTER_OPTIONAL_PARAMS) ParameterKey=VPCCIDR,ParameterValue=$(VPC_CIDR))
endif
ifdef HA_PROXY_MAX_COUNT
		$(eval CLUSTER_OPTIONAL_PARAMS := $(CLUSTER_OPTIONAL_PARAMS) ParameterKey=HAProxyMaxCount,ParameterValue=$(HA_PROXY_MAX_COUNT))
endif
ifdef HA_PROXY_DESIRED_COUNT
		$(eval CLUSTER_OPTIONAL_PARAMS := $(CLUSTER_OPTIONAL_PARAMS) ParameterKey=HAProxyDesiredCount,ParameterValue=$(HA_PROXY_DESIRED_COUNT))
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
		ParameterKey=InternetGatewayIdProp,ParameterValue=$(INTERNET_GATEWAY_ID) \
		ParameterKey=VPCIdProp,ParameterValue=$(VPC_ID) \
		ParameterKey=SubnetIdProp,ParameterValue=$(SUBNET_ID) \
		$(CLUSTER_OPTIONAL_PARAMS) \
		$(GERRIT_OPTIONAL_PRIMARY_VOLUME) \
		$(GERRIT_OPTIONAL_PARAMS_REPLICA_FILESYSTEM) \
		$(GERRIT_OPTIONAL_PARAMS_REPLICA_AUTO_SCALING_CAPACITY) \
		$(GERRIT_OPTIONAL_PARAMS_REPLICA_CAPACITY_PROVIDER)

service-primary-1: set-optional-params-metrics-cloudwatch set-optional-params-smtp \
					set-optional-params-multisite set-ldap-account-pattern \
					set-optional-gerrit-ulimits set-optional-jgit-conf \
					set-high-availability-optional-params
ifdef GERRIT_PRIMARY1_INSTANCE_ID
		$(eval PRIMARY1_SERVICE_OPTIONAL_PARAMS := $(PRIMARY1_SERVICE_OPTIONAL_PARAMS) ParameterKey=InstanceId,ParameterValue=$(GERRIT_PRIMARY1_INSTANCE_ID))
endif
ifdef LOAD_BALANCER_SCHEME
		$(eval PRIMARY1_SERVICE_OPTIONAL_PARAMS := $(PRIMARY1_SERVICE_OPTIONAL_PARAMS) ParameterKey=LoadBalancerScheme,ParameterValue=$(LOAD_BALANCER_SCHEME))
endif
ifdef REMOTE_REPLICATION_TARGET_HOST
		$(eval REMOTE_OPTIONAL_PARAMS := $(REMOTE_OPTIONAL_PARAMS) ParameterKey=RemoteReplicationTargetHost,ParameterValue=$(REMOTE_REPLICATION_TARGET_HOST))
endif
ifdef MULTISITE_GLOBAL_PROJECTS
		$(eval REMOTE_OPTIONAL_PARAMS := $(REMOTE_OPTIONAL_PARAMS) ParameterKey=MultiSiteGlobalProjects,ParameterValue=\"$(MULTISITE_GLOBAL_PROJECTS)\")
endif

	$(AWS_FC_COMMAND) create-stack \
		--stack-name $(SERVICE_PRIMARY1_STACK_NAME) \
		--capabilities CAPABILITY_IAM  \
		--template-body file://`pwd`/$(SERVICE_PRIMARY_TEMPLATE) \
		--region $(AWS_REGION) \
		--parameters \
		ParameterKey=GerritInstanceNumber,ParameterValue=1 \
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
		ParameterKey=Subdomain,ParameterValue=$(PRIMARY1_SUBDOMAIN) \
		ParameterKey=ReplicaSubdomain,ParameterValue=$(REPLICA_SUBDOMAIN) \
		ParameterKey=DockerRegistryUrl,ParameterValue=$(DOCKER_REGISTRY_URI) \
		ParameterKey=CertificateArn,ParameterValue=$(SSL_CERTIFICATE_ARN) \
		ParameterKey=HTTPHostPort,ParameterValue=$(HTTP_HOST_PORT_PRIMARY1) \
		ParameterKey=SSHHostPort,ParameterValue=$(SSH_HOST_PORT_PRIMARY1) \
		ParameterKey=GerritKeyPrefix,ParameterValue=$(GERRIT_KEY_PREFIX)\
		ParameterKey=DockerImage,ParameterValue=aws-gerrit/gerrit:$(IMAGE_TAG) \
		ParameterKey=PeerSubdomain,ParameterValue=$(PRIMARY2_SUBDOMAIN) \
		ParameterKey=LBSubdomain,ParameterValue=$(LB_SUBDOMAIN) \
		ParameterKey=GerritRAM,ParameterValue=$(GERRIT_RAM) \
		ParameterKey=GerritCPU,ParameterValue=$(GERRIT_CPU) \
		ParameterKey=GerritHeapLimit,ParameterValue=$(GERRIT_HEAP_LIMIT) \
		ParameterKey=JgitCacheSize,ParameterValue=$(JGIT_CACHE_SIZE) \
		$(HA_OPTIONAL_PARAMS) \
		$(JGIT_OPTIONAL_PARAMS) \
		$(MULTISITE_OPTIONAL_PARAMS) \
		$(REMOTE_OPTIONAL_PARAMS) \
		$(PRIMARY1_SERVICE_OPTIONAL_PARAMS) \
		$(LDAP_ACCOUNT_PATTERN_PARAM) \
		$(METRICS_CW_OPTIONAL_PARAMS) \
		$(SMTP_OPTIONAL_PARAMS) \
		$(GERRIT_ULIMITS)

service-primary-2: set-optional-params-metrics-cloudwatch set-optional-params-smtp \
					set-optional-params-multisite set-ldap-account-pattern \
					set-optional-gerrit-ulimits set-optional-jgit-conf \
					set-high-availability-optional-params
ifdef GERRIT_PRIMARY2_INSTANCE_ID
		$(eval PRIMARY2_SERVICE_OPTIONAL_PARAMS := $(PRIMARY2_SERVICE_OPTIONAL_PARAMS) ParameterKey=InstanceId,ParameterValue=$(GERRIT_PRIMARY2_INSTANCE_ID))
endif
ifdef LOAD_BALANCER_SCHEME
		$(eval PRIMARY2_SERVICE_OPTIONAL_PARAMS := $(PRIMARY2_SERVICE_OPTIONAL_PARAMS) ParameterKey=LoadBalancerScheme,ParameterValue=$(LOAD_BALANCER_SCHEME))
endif
ifdef REMOTE_REPLICATION_TARGET_HOST
		$(eval REMOTE_OPTIONAL_PARAMS := $(REMOTE_OPTIONAL_PARAMS) ParameterKey=RemoteReplicationTargetHost,ParameterValue=$(REMOTE_REPLICATION_TARGET_HOST))
endif
ifdef MULTISITE_GLOBAL_PROJECTS
		$(eval REMOTE_OPTIONAL_PARAMS := $(REMOTE_OPTIONAL_PARAMS) ParameterKey=MultiSiteGlobalProjects,ParameterValue=\"$(MULTISITE_GLOBAL_PROJECTS)\")
endif

	$(AWS_FC_COMMAND) create-stack \
		--stack-name $(SERVICE_PRIMARY2_STACK_NAME) \
		--capabilities CAPABILITY_IAM  \
		--template-body file://`pwd`/$(SERVICE_PRIMARY_TEMPLATE) \
		--region $(AWS_REGION) \
		--parameters \
		ParameterKey=GerritInstanceNumber,ParameterValue=2 \
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
		ParameterKey=Subdomain,ParameterValue=$(PRIMARY2_SUBDOMAIN) \
		ParameterKey=ReplicaSubdomain,ParameterValue=$(REPLICA_SUBDOMAIN) \
		ParameterKey=DockerRegistryUrl,ParameterValue=$(DOCKER_REGISTRY_URI) \
		ParameterKey=CertificateArn,ParameterValue=$(SSL_CERTIFICATE_ARN) \
		ParameterKey=HTTPHostPort,ParameterValue=$(HTTP_HOST_PORT_PRIMARY2) \
		ParameterKey=SSHHostPort,ParameterValue=$(SSH_HOST_PORT_PRIMARY2) \
		ParameterKey=GerritKeyPrefix,ParameterValue=$(GERRIT_KEY_PREFIX)\
		ParameterKey=DockerImage,ParameterValue=aws-gerrit/gerrit:$(IMAGE_TAG) \
		ParameterKey=PeerSubdomain,ParameterValue=$(PRIMARY1_SUBDOMAIN) \
		ParameterKey=LBSubdomain,ParameterValue=$(LB_SUBDOMAIN) \
		ParameterKey=ReindexAtSartup,ParameterValue=true \
		ParameterKey=GerritRAM,ParameterValue=$(GERRIT_RAM) \
		ParameterKey=GerritCPU,ParameterValue=$(GERRIT_CPU) \
		ParameterKey=GerritHeapLimit,ParameterValue=$(GERRIT_HEAP_LIMIT) \
		ParameterKey=JgitCacheSize,ParameterValue=$(JGIT_CACHE_SIZE) \
		$(HA_OPTIONAL_PARAMS) \
		$(JGIT_OPTIONAL_PARAMS) \
		$(MULTISITE_OPTIONAL_PARAMS) \
		$(REMOTE_OPTIONAL_PARAMS) \
		$(PRIMARY2_SERVICE_OPTIONAL_PARAMS) \
		$(LDAP_ACCOUNT_PATTERN_PARAM) \
		$(METRICS_CW_OPTIONAL_PARAMS) \
		$(SMTP_OPTIONAL_PARAMS) \
		$(GERRIT_ULIMITS)

service-replication:
	$(AWS_FC_COMMAND) create-stack \
		--stack-name $(SERVICE_REPLICATION_STACK_NAME) \
		--capabilities CAPABILITY_IAM  \
		--template-body file://`pwd`/$(SERVICE_REPLICATION_TEMPLATE) \
		--region $(AWS_REGION) \
		--parameters \
		ParameterKey=GitReplicationServiceName,ParameterValue=$(SERVICE_REPLICATION_STACK_NAME) \
		ParameterKey=ClusterStackName,ParameterValue=$(CLUSTER_STACK_NAME) \
		ParameterKey=TemplateBucketName,ParameterValue=$(TEMPLATE_BUCKET_NAME) \
		ParameterKey=DockerRegistryUrl,ParameterValue=$(DOCKER_REGISTRY_URI) \
		ParameterKey=DesiredCount,ParameterValue=$(SERVICE_REPLICATION_DESIRED_COUNT) \
		ParameterKey=GerritKeyPrefix,ParameterValue=$(GERRIT_KEY_PREFIX) \
		ParameterKey=HostedZoneName,ParameterValue=$(HOSTED_ZONE_NAME) \
		ParameterKey=GitReplicationSubdomain,ParameterValue=$(GIT_REPLICATION_SUBDOMAIN)

service-replica: set-optional-params-metrics-cloudwatch \
					set-ldap-account-pattern \
					set-optional-gerrit-ulimits \
					set-optional-jgit-conf \
					set-optional-params-for-replica-auto-scaling-capacity \
					set-optional-params-for-replica-auto-scaling-policy

ifdef GERRIT_REPLICA_INSTANCE_ID
		$(eval REPLICA_SERVICE_OPTIONAL_PARAMS := $(REPLICA_SERVICE_OPTIONAL_PARAMS) ParameterKey=InstanceId,ParameterValue=$(GERRIT_REPLICA_INSTANCE_ID))
endif
ifdef LOAD_BALANCER_SCHEME
		$(eval REPLICA_SERVICE_OPTIONAL_PARAMS := $(REPLICA_SERVICE_OPTIONAL_PARAMS) ParameterKey=LoadBalancerScheme,ParameterValue=$(LOAD_BALANCER_SCHEME))
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
		ParameterKey=Subdomain,ParameterValue=$(REPLICA_SUBDOMAIN) \
		ParameterKey=DockerRegistryUrl,ParameterValue=$(DOCKER_REGISTRY_URI) \
		ParameterKey=CertificateArn,ParameterValue=$(SSL_CERTIFICATE_ARN) \
		ParameterKey=GerritKeyPrefix,ParameterValue=$(GERRIT_KEY_PREFIX)\
		ParameterKey=GerritDockerImage,ParameterValue=aws-gerrit/gerrit:$(IMAGE_TAG) \
		ParameterKey=GerritRAM,ParameterValue=$(GERRIT_RAM) \
		ParameterKey=GerritCPU,ParameterValue=$(GERRIT_CPU) \
		ParameterKey=GerritHeapLimit,ParameterValue=$(GERRIT_HEAP_LIMIT) \
		ParameterKey=JgitCacheSize,ParameterValue=$(JGIT_CACHE_SIZE) \
		$(JGIT_OPTIONAL_PARAMS) \
		$(LDAP_ACCOUNT_PATTERN_PARAM) \
		$(REPLICA_SERVICE_OPTIONAL_PARAMS) \
		$(METRICS_CW_OPTIONAL_PARAMS) \
		$(GERRIT_ULIMITS) \
		$(GERRIT_OPTIONAL_PARAMS_REPLICA_AUTO_SCALING_CAPACITY) \
		$(GERRIT_OPTIONAL_PARAMS_REPLICA_AUTO_SCALING_POLICY)

service-lb:
ifdef LOAD_BALANCER_SCHEME
		$(eval SERVICE_OPTIONAL_PARAMS := $(SERVICE_OPTIONAL_PARAMS) ParameterKey=LoadBalancerScheme,ParameterValue=$(LOAD_BALANCER_SCHEME))
endif
ifdef HA_PROXY_DESIRED_COUNT
		$(eval SERVICE_OPTIONAL_PARAMS := $(SERVICE_OPTIONAL_PARAMS) ParameterKey=DesiredCount,ParameterValue=$(HA_PROXY_DESIRED_COUNT))
endif

	$(AWS_FC_COMMAND) create-stack \
		--stack-name $(LOAD_BALANCER_STACK_NAME) \
		--capabilities CAPABILITY_IAM  \
		--template-body file://`pwd`/$(LOAD_BALANCER_TEMPLATE) \
		--region $(AWS_REGION) \
		--parameters \
		ParameterKey=ClusterStackName,ParameterValue=$(CLUSTER_STACK_NAME) \
		ParameterKey=Primary1ServiceStackName,ParameterValue=$(SERVICE_PRIMARY1_STACK_NAME) \
		ParameterKey=Primary2ServiceStackName,ParameterValue=$(SERVICE_PRIMARY2_STACK_NAME) \
		ParameterKey=HostedZoneName,ParameterValue=$(HOSTED_ZONE_NAME) \
		ParameterKey=DockerRegistryUrl,ParameterValue=$(DOCKER_REGISTRY_URI) \
		ParameterKey=GerritKeyPrefix,ParameterValue=$(GERRIT_KEY_PREFIX)\
		ParameterKey=CertificateArn,ParameterValue=$(SSL_CERTIFICATE_ARN) \
		ParameterKey=Subdomain,ParameterValue=$(LB_SUBDOMAIN) \
		ParameterKey=TemplateBucketName,ParameterValue=$(TEMPLATE_BUCKET_NAME) \
		ParameterKey=HAProxyDockerImage,ParameterValue=aws-gerrit/haproxy:$(HAPROXY_HEAD_SHA1) \
		ParameterKey=SidecarDockerImage,ParameterValue=aws-gerrit/syslog-sidecar:$(SYSLOG_HEAD_SHA1) \
		$(SERVICE_OPTIONAL_PARAMS)

dns-routing:
	$(AWS_FC_COMMAND) create-stack \
		--stack-name $(DNS_ROUTING_STACK_NAME) \
		--capabilities CAPABILITY_IAM  \
		--template-body file://`pwd`/$(DNS_ROUTING_TEMPLATE) \
		--region $(AWS_REGION) \
		--parameters \
		ParameterKey=Primary1ServiceStackName,ParameterValue=$(SERVICE_PRIMARY1_STACK_NAME) \
		ParameterKey=Primary2ServiceStackName,ParameterValue=$(SERVICE_PRIMARY2_STACK_NAME) \
		ParameterKey=LBServiceStackName,ParameterValue=$(LOAD_BALANCER_STACK_NAME)

dashboard:
ifeq ($(METRICS_CLOUDWATCH_ENABLED),true)
ifdef GERRIT_PRIMARY1_INSTANCE_ID
		$(eval DASHBOARD_OPTIONAL_PARAMS := $(DASHBOARD_OPTIONAL_PARAMS) ParameterKey=Primary1InstanceId,ParameterValue=$(GERRIT_PRIMARY1_INSTANCE_ID))
endif
ifdef GERRIT_PRIMARY2_INSTANCE_ID
		$(eval DASHBOARD_OPTIONAL_PARAMS := $(DASHBOARD_OPTIONAL_PARAMS) ParameterKey=Primary2InstanceId,ParameterValue=$(GERRIT_PRIMARY2_INSTANCE_ID))
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

wait-for-cluster-creation:
	@echo "*** Wait for cluster stack '$(CLUSTER_STACK_NAME)' creation"
	$(AWS_FC_COMMAND) wait stack-create-complete \
	--stack-name $(CLUSTER_STACK_NAME) \
	--region $(AWS_REGION)
	@echo "*** Cluster stack '$(CLUSTER_STACK_NAME)' created"

wait-for-service-primary-1-creation:
	@echo "*** Wait for service primary stack '$(SERVICE_PRIMARY1_STACK_NAME)' creation"
	$(AWS_FC_COMMAND) wait stack-create-complete \
	--stack-name $(SERVICE_PRIMARY1_STACK_NAME) \
	--region $(AWS_REGION)
	@echo "*** Service stack '$(SERVICE_PRIMARY1_STACK_NAME)' created"

wait-for-service-replication-creation:
	@echo "*** Wait for service replication stack '$(SERVICE_REPLICATION_STACK_NAME)' creation"
	$(AWS_FC_COMMAND) wait stack-create-complete \
	--stack-name $(SERVICE_REPLICATION_STACK_NAME) \
	--region $(AWS_REGION)
	@echo "*** Service stack '$(SERVICE_REPLICATION_STACK_NAME)' created"

wait-for-service-primary-2-creation:
	@echo "*** Wait for service primary stack '$(SERVICE_PRIMARY2_STACK_NAME)' creation"
	$(AWS_FC_COMMAND) wait stack-create-complete \
	--stack-name $(SERVICE_PRIMARY2_STACK_NAME) \
	--region $(AWS_REGION)
	@echo "*** Service stack '$(SERVICE_PRIMARY2_STACK_NAME)' created"

wait-for-service-replica-creation:
	@echo "*** Wait for service replica stack '$(SERVICE_REPLICA_STACK_NAME)' creation"
	$(AWS_FC_COMMAND) wait stack-create-complete \
	--stack-name $(SERVICE_REPLICA_STACK_NAME) \
	--region $(AWS_REGION)
	@echo "*** Service stack '$(SERVICE_REPLICA_STACK_NAME)' created"

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

wait-for-service-primary-1-deletion:
	@echo "*** Wait for service primary stack '$(SERVICE_PRIMARY1_STACK_NAME)' deletion"
	$(AWS_FC_COMMAND) wait stack-delete-complete \
	--stack-name $(SERVICE_PRIMARY1_STACK_NAME) \
	--region $(AWS_REGION)
	@echo "*** Service stack primary '$(SERVICE_PRIMARY1_STACK_NAME)' deleted"

wait-for-service-primary-2-deletion:
	@echo "*** Wait for service primary stack '$(SERVICE_PRIMARY2_STACK_NAME)' deletion"
	$(AWS_FC_COMMAND) wait stack-delete-complete \
	--stack-name $(SERVICE_PRIMARY2_STACK_NAME) \
	--region $(AWS_REGION)
	@echo "*** Service stack primary '$(SERVICE_PRIMARY2_STACK_NAME)' deleted"

wait-for-service-replica-deletion:
	@echo "*** Wait for service replica stack '$(SERVICE_REPLICA_STACK_NAME)' deletion"
	$(AWS_FC_COMMAND) wait stack-delete-complete \
	--stack-name $(SERVICE_REPLICA_STACK_NAME) \
	--region $(AWS_REGION)
	@echo "*** Service stack replica '$(SERVICE_REPLICA_STACK_NAME)' deleted"

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

wait-for-service-replication-deletion:
	@echo "*** Wait for service replication stack '$(SERVICE_REPLICATION_STACK_NAME)' deletion"
	$(AWS_FC_COMMAND) wait stack-delete-complete \
	--stack-name $(SERVICE_REPLICATION_STACK_NAME) \
	--region $(AWS_REGION)
	@echo "*** Service stack '$(SERVICE_REPLICATION_STACK_NAME)' deleted"

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

delete-service-primary-1:
	$(AWS_FC_COMMAND) delete-stack \
	--stack-name $(SERVICE_PRIMARY1_STACK_NAME) \
	--region $(AWS_REGION)

delete-service-primary-2:
	$(AWS_FC_COMMAND) delete-stack \
	--stack-name $(SERVICE_PRIMARY2_STACK_NAME) \
	--region $(AWS_REGION)

delete-service-replica:
	$(AWS_FC_COMMAND) delete-stack \
	--stack-name $(SERVICE_REPLICA_STACK_NAME) \
	--region $(AWS_REGION)

delete-service-lb:
	$(AWS_FC_COMMAND) delete-stack \
	--stack-name $(LOAD_BALANCER_STACK_NAME) \
	--region $(AWS_REGION)

delete-service-replication:
	$(AWS_FC_COMMAND) delete-stack \
	--stack-name $(SERVICE_REPLICATION_STACK_NAME) \
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
						delete-service-lb wait-for-service-lb-deletion \
						delete-service-primary-1 delete-service-primary-2 delete-service-replica \
						wait-for-service-primary-1-deletion wait-for-service-primary-2-deletion wait-for-service-replica-deletion \
						$(optional_dashboard_targets_deletion) \
						$(optional_replication_targets_deletion) \
						$(optional_git_gc_targets_deletion) \
						delete-cluster wait-for-cluster-deletion

delete-all-including-retained-stack: confirm-persistent-stack-deletion delete-all delete-git-primary-persistent-stack delete-git-replica-persistent-stack delete-network-persistent-stack

delete-git-primary-persistent-stack:

	$(eval EFS_STACK_NAME := $(shell $(AWS_FC_COMMAND) list-stacks --stack-status-filter CREATE_COMPLETE --query "StackSummaries[*].StackName" | jq -r '.[]| select(startswith("$(CLUSTER_STACK_NAME)-PrimaryGitFileSystemPermanentStack"))'))

	$(if $(EFS_STACK_NAME), \
		$(AWS_FC_COMMAND) delete-stack \
			--stack-name $(EFS_STACK_NAME) \
			--region $(AWS_REGION) && \
		echo "*** Wait for Git persistent stack '$(EFS_STACK_NAME)' deletion" && \
		$(AWS_FC_COMMAND) wait stack-delete-complete \
			--stack-name $(EFS_STACK_NAME) \
			--region $(AWS_REGION) && \
		echo "*** Git persistent stack '$(EFS_STACK_NAME)' deleted" \
		, \
		echo "No Git persistent stack found. Nothing to do." \
	)

gerrit-publish:
ifeq ($(MULTISITE_ENABLED),true)
	$(MAKE) -C ../gerrit gerrit-publish RECIPE=dual-primary PLUGINS="$(MULTI_SITE_PLUGINS)" PLUGINS_LIBS_LINKS="$(MULTI_SITE_PLUGINS_LIBS_LINKS)" MAVEN_LIBS="$(MULTI_SITE_MAVEN_LIBS)"
else
	$(MAKE) -C ../gerrit gerrit-publish RECIPE=dual-primary PLUGINS="$(SINGLE_SITE_PLUGINS)"
endif

haproxy-publish:
	$(MAKE) -C haproxy haproxy-publish

syslog-sidecar-publish:
	$(MAKE) -C syslog-sidecar syslog-sidecar-publish

git-daemon-publish:
	$(MAKE) -C ../primary-replica/git-daemon git-daemon-publish

git-ssh-publish:
	$(MAKE) -C ../primary-replica/git-ssh git-ssh-publish

set-high-availability-optional-params:
	$(eval HA_OPTIONAL_PARAMS=)
ifdef AUTOREINDEX_POLL_INTERVAL
		$(eval HA_OPTIONAL_PARAMS := ParameterKey=AutoReindexPollInterval,ParameterValue=$(AUTOREINDEX_POLL_INTERVAL))
endif

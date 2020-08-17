include ../common.env # Must be included before setup.env because the latter depends on it
include setup.env
include ../Makefile.common

CLUSTER_TEMPLATE:=cf-cluster.yml
SERVICE_MASTER_TEMPLATE:=cf-service-master.yml
SERVICE_SLAVE_TEMPLATE:=cf-service-slave.yml
DNS_ROUTING_TEMPLATE:=cf-dns-route.yml
LOAD_BALANCER_TEMPLATE:=cf-service-lb.yml
SERVICE_REPLICATION_TEMPLATE:=cf-service-replication.yml
AWS_FC_COMMAND=export AWS_PAGER=;aws cloudformation

.PHONY: create-all delete-all \
				wait-for-replication-creation wait-for-service-replication-deletion service-replication delete-service-replication \
				cluster cluster-keys service-master-1 service-master-2 service-slave dns-routing \
				wait-for-cluster-creation wait-for-service-master-1-creation wait-for-service-master-2-creation wait-for-service-slave-creation wait-for-dns-routing-creation \
				wait-for-cluster-deletion wait-for-service-master-1-deletion wait-for-service-master-2-deletion wait-for-service-slave-deletion wait-for-dns-routing-deletion \
				service-lb wait-for-service-lb-deletion wait-for-service-lb-creation \
				gerrit-build gerrit-publish haproxy-publish syslog-sidecar-publish

ifeq ($(REPLICATION_SERVICE_ENABLED),true)
optional_replication_targets=service-replication wait-for-service-replication-creation
endif

create-all: upload-common-templates \
						git-daemon-publish git-ssh-publish \
						gerrit-publish haproxy-publish syslog-sidecar-publish \
						cluster wait-for-cluster-creation \
						$(optional_replication_targets) \
						service-slave service-master-1 \
						wait-for-service-master-1-creation wait-for-service-slave-creation \
						service-master-2 wait-for-service-master-2-creation \
						service-lb wait-for-service-lb-creation \
						dns-routing wait-for-dns-routing-creation

cluster: cluster-keys
ifdef CLUSTER_INSTANCE_TYPE
		$(eval CLUSTER_OPTIONAL_PARAMS := $(CLUSTER_OPTIONAL_PARAMS) ParameterKey=InstanceType,ParameterValue=$(CLUSTER_INSTANCE_TYPE))
endif
ifdef FILESYSTEM_THROUGHPUT_MODE
		$(eval CLUSTER_OPTIONAL_PARAMS := $(CLUSTER_OPTIONAL_PARAMS) ParameterKey=FileSystemThroughputMode,ParameterValue=$(FILESYSTEM_THROUGHPUT_MODE))
endif
ifdef FILESYSTEM_PROVISIONED_THROUGHPUT_IN_MIBPS
		$(eval CLUSTER_OPTIONAL_PARAMS := $(CLUSTER_OPTIONAL_PARAMS) ParameterKey=ProvisionedThroughputInMibps,ParameterValue=$(FILESYSTEM_PROVISIONED_THROUGHPUT_IN_MIBPS))
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

service-master-1: set-optional-params-metrics-cloudwatch set-optional-params-smtp set-optional-params-multisite
ifdef GERRIT_MASTER1_INSTANCE_ID
		$(eval MASTER1_SERVICE_OPTIONAL_PARAMS := $(MASTER1_SERVICE_OPTIONAL_PARAMS) ParameterKey=InstanceId,ParameterValue=$(GERRIT_MASTER1_INSTANCE_ID))
endif
ifdef LDAP_ACCOUNT_PATTERN
		$(eval MASTER1_SERVICE_OPTIONAL_PARAMS := $(MASTER1_SERVICE_OPTIONAL_PARAMS) ParameterKey=LDAPAccountPattern,ParameterValue=\"$(LDAP_ACCOUNT_PATTERN)\")
endif
ifdef REMOTE_REPLICATION_TARGET_HOST
		$(eval REMOTE_OPTIONAL_PARAMS := $(REMOTE_OPTIONAL_PARAMS) ParameterKey=RemoteReplicationTargetHost,ParameterValue=$(REMOTE_REPLICATION_TARGET_HOST))
endif

	$(AWS_FC_COMMAND) create-stack \
		--stack-name $(SERVICE_MASTER1_STACK_NAME) \
		--capabilities CAPABILITY_IAM  \
		--template-body file://`pwd`/$(SERVICE_MASTER_TEMPLATE) \
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
		ParameterKey=Subdomain,ParameterValue=$(MASTER1_SUBDOMAIN) \
		ParameterKey=SlaveSubdomain,ParameterValue=$(SLAVE_SUBDOMAIN) \
		ParameterKey=DockerRegistryUrl,ParameterValue=$(DOCKER_REGISTRY_URI) \
		ParameterKey=CertificateArn,ParameterValue=$(SSL_CERTIFICATE_ARN) \
		ParameterKey=HTTPHostPort,ParameterValue=$(HTTP_HOST_PORT_MASTER1) \
		ParameterKey=SSHHostPort,ParameterValue=$(SSH_HOST_PORT_MASTER1) \
		ParameterKey=GerritKeyPrefix,ParameterValue=$(GERRIT_KEY_PREFIX)\
		ParameterKey=DockerImage,ParameterValue=aws-gerrit/gerrit:$(IMAGE_TAG) \
		ParameterKey=PeerSubdomain,ParameterValue=$(MASTER2_SUBDOMAIN) \
		ParameterKey=LBSubdomain,ParameterValue=$(LB_SUBDOMAIN) \
		ParameterKey=SlaveServiceStackName,ParameterValue=$(SERVICE_SLAVE_STACK_NAME) \
		ParameterKey=GerritRAM,ParameterValue=$(GERRIT_RAM) \
		ParameterKey=GerritCPU,ParameterValue=$(GERRIT_CPU) \
		ParameterKey=GerritHeapLimit,ParameterValue=$(GERRIT_HEAP_LIMIT) \
		ParameterKey=JgitCacheSize,ParameterValue=$(JGIT_CACHE_SIZE) \
		$(MULTISITE_OPTIONAL_PARAMS) \
		$(REMOTE_OPTIONAL_PARAMS) \
		$(MASTER1_SERVICE_OPTIONAL_PARAMS) \
		$(METRICS_CW_OPTIONAL_PARAMS) \
		$(SMTP_OPTIONAL_PARAMS)

service-master-2: set-optional-params-metrics-cloudwatch set-optional-params-smtp set-optional-params-multisite
ifdef GERRIT_MASTER2_INSTANCE_ID
		$(eval MASTER2_SERVICE_OPTIONAL_PARAMS := $(MASTER2_SERVICE_OPTIONAL_PARAMS) ParameterKey=InstanceId,ParameterValue=$(GERRIT_MASTER2_INSTANCE_ID))
endif
ifdef LDAP_ACCOUNT_PATTERN
		$(eval MASTER2_SERVICE_OPTIONAL_PARAMS := $(MASTER2_SERVICE_OPTIONAL_PARAMS) ParameterKey=LDAPAccountPattern,ParameterValue=\"$(LDAP_ACCOUNT_PATTERN)\")
endif
ifdef REMOTE_REPLICATION_TARGET_HOST
		$(eval REMOTE_OPTIONAL_PARAMS := $(REMOTE_OPTIONAL_PARAMS) ParameterKey=RemoteReplicationTargetHost,ParameterValue=$(REMOTE_REPLICATION_TARGET_HOST))
endif

	$(AWS_FC_COMMAND) create-stack \
		--stack-name $(SERVICE_MASTER2_STACK_NAME) \
		--capabilities CAPABILITY_IAM  \
		--template-body file://`pwd`/$(SERVICE_MASTER_TEMPLATE) \
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
		ParameterKey=Subdomain,ParameterValue=$(MASTER2_SUBDOMAIN) \
		ParameterKey=SlaveSubdomain,ParameterValue=$(SLAVE_SUBDOMAIN) \
		ParameterKey=DockerRegistryUrl,ParameterValue=$(DOCKER_REGISTRY_URI) \
		ParameterKey=CertificateArn,ParameterValue=$(SSL_CERTIFICATE_ARN) \
		ParameterKey=HTTPHostPort,ParameterValue=$(HTTP_HOST_PORT_MASTER2) \
		ParameterKey=SSHHostPort,ParameterValue=$(SSH_HOST_PORT_MASTER2) \
		ParameterKey=GerritKeyPrefix,ParameterValue=$(GERRIT_KEY_PREFIX)\
		ParameterKey=DockerImage,ParameterValue=aws-gerrit/gerrit:$(IMAGE_TAG) \
		ParameterKey=PeerSubdomain,ParameterValue=$(MASTER1_SUBDOMAIN) \
		ParameterKey=LBSubdomain,ParameterValue=$(LB_SUBDOMAIN) \
		ParameterKey=SlaveServiceStackName,ParameterValue=$(SERVICE_SLAVE_STACK_NAME) \
		ParameterKey=ReindexAtSartup,ParameterValue=true \
		ParameterKey=GerritRAM,ParameterValue=$(GERRIT_RAM) \
		ParameterKey=GerritCPU,ParameterValue=$(GERRIT_CPU) \
		ParameterKey=GerritHeapLimit,ParameterValue=$(GERRIT_HEAP_LIMIT) \
		ParameterKey=JgitCacheSize,ParameterValue=$(JGIT_CACHE_SIZE) \
		$(MULTISITE_OPTIONAL_PARAMS) \
		$(REMOTE_OPTIONAL_PARAMS) \
		$(MASTER2_SERVICE_OPTIONAL_PARAMS) \
		$(METRICS_CW_OPTIONAL_PARAMS) \
		$(SMTP_OPTIONAL_PARAMS)

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

service-slave: set-optional-params-metrics-cloudwatch
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

service-lb:
ifdef LOAD_BALANCER_SCHEME
		$(eval SERVICE_OPTIONAL_PARAMS := $(SERVICE_OPTIONAL_PARAMS) ParameterKey=LoadBalancerScheme,ParameterValue=$(LOAD_BALANCER_SCHEME))
endif

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
		ParameterKey=HAProxyDockerImage,ParameterValue=aws-gerrit/haproxy:$(HAPROXY_HEAD_SHA1) \
		ParameterKey=SidecarDockerImage,ParameterValue=aws-gerrit/syslog-sidecar:$(SYSLOG_HEAD_SHA1) \
		$(REPLICATION_SERVICE_OPTIONAL_PARAMS) \
		$(SERVICE_OPTIONAL_PARAMS)

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

wait-for-service-replication-creation:
	@echo "*** Wait for service replication stack '$(SERVICE_REPLICATION_STACK_NAME)' creation"
	$(AWS_FC_COMMAND) wait stack-create-complete \
	--stack-name $(SERVICE_REPLICATION_STACK_NAME) \
	--region $(AWS_REGION)
	@echo "*** Service stack '$(SERVICE_REPLICATION_STACK_NAME)' created"

wait-for-service-master-2-creation:
	@echo "*** Wait for service master stack '$(SERVICE_MASTER2_STACK_NAME)' creation"
	$(AWS_FC_COMMAND) wait stack-create-complete \
	--stack-name $(SERVICE_MASTER2_STACK_NAME) \
	--region $(AWS_REGION)
	@echo "*** Service stack '$(SERVICE_MASTER2_STACK_NAME)' created"

wait-for-service-slave-creation:
	@echo "*** Wait for service slave stack '$(SERVICE_SLAVE_STACK_NAME)' creation"
	$(AWS_FC_COMMAND) wait stack-create-complete \
	--stack-name $(SERVICE_SLAVE_STACK_NAME) \
	--region $(AWS_REGION)
	@echo "*** Service stack '$(SERVICE_SLAVE_STACK_NAME)' created"

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

wait-for-service-slave-deletion:
	@echo "*** Wait for service slave stack '$(SERVICE_SLAVE_STACK_NAME)' deletion"
	$(AWS_FC_COMMAND) wait stack-delete-complete \
	--stack-name $(SERVICE_SLAVE_STACK_NAME) \
	--region $(AWS_REGION)
	@echo "*** Service stack slave '$(SERVICE_SLAVE_STACK_NAME)' deleted"

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

delete-service-slave:
	$(AWS_FC_COMMAND) delete-stack \
	--stack-name $(SERVICE_SLAVE_STACK_NAME) \
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

delete-all: delete-dns-routing wait-for-dns-routing-deletion \
						delete-service-lb wait-for-service-lb-deletion \
						delete-service-master-1 delete-service-master-2 delete-service-slave \
						wait-for-service-master-1-deletion wait-for-service-master-2-deletion wait-for-service-slave-deletion \
						delete-service-replication wait-for-service-replication-deletion \
						delete-cluster wait-for-cluster-deletion

gerrit-publish:
	$(MAKE) -C ../gerrit gerrit-publish RECIPE=dual-master

haproxy-publish:
	$(MAKE) -C haproxy haproxy-publish

syslog-sidecar-publish:
	$(MAKE) -C syslog-sidecar syslog-sidecar-publish

git-daemon-publish:
	$(MAKE) -C ../master-slave/git-daemon git-daemon-publish

git-ssh-publish:
	$(MAKE) -C ../master-slave/git-ssh git-ssh-publish
